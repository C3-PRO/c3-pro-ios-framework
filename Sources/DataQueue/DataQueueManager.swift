//
//  DataQueueManager.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 6/2/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import SMART


/**
Class to manage resources in a filesystem-based data queue.
*/
class DataQueueManager {
	
	/// The filename to prepend to the running queue position number.
	static var prefix = "QueuedResource-"
	
	/// The file extension, likely "json".
	static var fileExtension = "json"
	
	/// The Server instance we'll be talking to.
	unowned let server: Server
	
	/// The logger to use, if any.
	var logger: OAuth2Logger?
	
	/// The absolute path to the receiver's queue directory; individual per the receiver's host.
	let queueDirectory: String
	
	init(fhirServer: Server, directory: String) {
		server = fhirServer
		queueDirectory = directory
		#if DEBUG
		let logger = OAuth2DebugLogger(.Trace)
		let manager = NSFileManager()
		if let iterator = manager.enumeratorAtPath(queueDirectory) {
			logger.trace("C3-PRO", msg: "Initialized data queue at «\(queueDirectory)»")
			for item in iterator {
				logger.trace("C3-PRO", msg: "Waiting: \(item)")
			}
		}
		#endif
	}
	
	
	// MARK: - File Handling
	
	/** The filename of a resource at the given queue position. */
	func fileNameForSequence(seq: Int) -> String {
		return ("\(self.dynamicType.prefix)\(seq)" as NSString).stringByAppendingPathExtension(self.dynamicType.fileExtension)!
	}
	
	/// The data writing options when storing a resource to the queue.
	var fileProtection: NSDataWritingOptions {
		return NSDataWritingOptions.DataWritingFileProtectionCompleteUnlessOpen
	}
	
	
	// MARK: - Queue Directory
	
	var currentlyDequeueing: QueuedResource?
	
	func isDequeueing(resource: Resource) -> Bool {
		if let dequeueing = currentlyDequeueing?.resource where dequeueing === resource {
			return true
		}
		return false
	}
	
	/** Checks if the directory for queued files exists on disk, creating them and adjusting the file protection status if necessary. */
	func ensureHasDirectory() {
		let manager = NSFileManager.defaultManager()
		
		var isDir: ObjCBool = true
		if !manager.fileExistsAtPath(queueDirectory, isDirectory: &isDir) || !isDir {
			do {
				try manager.createDirectoryAtPath(queueDirectory, withIntermediateDirectories: true, attributes: nil)
			}
			catch let error {
				fatalError("DataQueue: Failed to create queue directory: \(error)")
			}
		}
	}
	
	/**
	Looks at all resources in the queue and returns the lowest and highest position, if any.
	
	- parameter manager: The NSFileManager to use
	- returns: A tuple of (min, max) indices
	*/
	func currentQueueRange(manager: NSFileManager) -> (min: Int, max: Int)? {
		var myMin: Int?
		var myMax: Int?
		
		do {
			let files = try manager.contentsOfDirectoryAtPath(queueDirectory)
			for anyFile in files {
				let file = anyFile as NSString
				let pure = file.stringByDeletingPathExtension.stringByReplacingOccurrencesOfString(self.dynamicType.prefix, withString: "") as NSString
				myMin = min(myMin ?? pure.integerValue, pure.integerValue)
				myMax = max(myMax ?? pure.integerValue, pure.integerValue)
			}
		}
		catch let error {
			logger?.debug("C3-PRO", msg: "Failed to read current queue: \(error)")
		}
		
		return (nil != myMin) ? (min: myMin!, max: myMax!) : nil
	}
	
	
	// MARK: - Queue Management
	
	/**
	Enqueues the given resource.
	
	- parameter resource: The FHIR Resource to enqueue
	*/
	func enqueueResource(resource: Resource) {
		ensureHasDirectory()
		
		// get next sequence number
		var seq = currentQueueRange(NSFileManager())?.max ?? 0
		seq += 1
		
		// store new resoure to queue
		let path = (queueDirectory as NSString).stringByAppendingPathComponent(fileNameForSequence(seq))
		do {
			let data = try NSJSONSerialization.dataWithJSONObject(resource.asJSON(), options: [])
			try data.writeToFile(path, options: fileProtection)
			logger?.debug("C3-PRO", msg: "Enqueued resource at \(path)")
		}
		catch let error {
			logger?.debug("C3-PRO", msg: "Failed to serialize or enqueue JSON: \(error)")
		}
	}
	
	/** Convenience method for internal use; POST requests should be DataRequests so this should never fail. */
	func enqueueResourceInHandler(handler: FHIRServerRequestHandler) {
		if let resource = handler.resource {
			enqueueResource(resource)
		}
	}
	
	/** Starts flushing the queue, oldest resources first, until no more resources are enqueued or an error occurs. */
	func flush(callback: ((error: ErrorType?) -> Void)) {
		dequeueFirst { [weak self] didDequeue, error in
			if let error = error {
				callback(error: error)
			}
			else if didDequeue {
				if let this = self {
					this.flush(callback)
				}
				else {
					callback(error: C3Error.DataQueueFlushHalted)
				}
			}
			else {
				callback(error: nil)
			}
		}
	}
	
	/**
	Looks and deserializes the first resource in the queue, then issues a `create` command to POST it to the server.
	
	- parameter callback: The callback to call. "didDequeue" is true if the resource was successfully dequeued. "error" is nil on success or
	if there was no file to dequeue (in which case _didDequeue_ would be false)
	*/
	func dequeueFirst(callback: ((didDequeue: Bool, error: ErrorType?) -> Void)) {
		if nil != currentlyDequeueing {
			c3_warn("already dequeueing")
			callback(didDequeue: false, error: nil)
			return
		}
		
		if let first = firstInQueue() {
			logger?.debug("C3-PRO", msg: "Dequeueing first in queue: \(first.path)")
			do {
				try first.readFromFile()
				currentlyDequeueing = first
				let cb: FHIRErrorCallback = { cError in
					if nil == cError {
						self.clearCurrentlyDequeueing()
					}
					callback(didDequeue: (nil == cError), error: cError)
				}
				
				if nil != first.resource!.id {
					first.resource!._server = server
					first.resource!.update(cb)
				}
				else {
					first.resource!.create(server, callback: cb)
				}
			}
			catch let error {
				c3_warn("failed to read resource data: \(error)")
				// TODO: figure out what to do (file should be readable at this point)
				callback(didDequeue: false, error: nil)
			}
		}
		else {
			callback(didDequeue: false, error: nil)
		}
	}
	
	/** Deletes the resource in `currentlyDequeueing` from the queue. */
	func clearCurrentlyDequeueing() {
		if let path = currentlyDequeueing?.path {
			let manager = NSFileManager()
			do {
				try manager.removeItemAtPath(path)
				currentlyDequeueing = nil
			}
			catch let error {
				// TODO: figure out what to do
				c3_warn("failed to remove queued resource \(path): \(error)")
			}
		}
	}
	
	/**
	Returns the first resource in the queue, but **only** if it is readable.
	
	- returns: The first resource in the queue, as `QueuedResource`
	*/
	final func firstInQueue() -> QueuedResource? {
		let manager = NSFileManager()
		if let first = currentQueueRange(manager)?.min {
			let path = (queueDirectory as NSString).stringByAppendingPathComponent(fileNameForSequence(first))
			if manager.isReadableFileAtPath(path) {
				return QueuedResource(path: path)
			}
			logger?.debug("C3-PRO", msg: "Have file in queue but it is not readable, waiting for next call")
		}
		return nil
	}
}

