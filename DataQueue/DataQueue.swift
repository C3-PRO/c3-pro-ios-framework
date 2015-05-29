//
//  DataQueue.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 5/28/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART

let CHIPDataQueueErrorKey = "CHIPDataQueueError"


/**
    The (FIFO) DataQueue is a special FHIRServer implementation that will enqueue FHIR resources to disk if a first attempt at issuing a
    `create` command fails. The queue can subsequently be flushed to re-attempt creating the resources on the FHIR server, in their original
    order.
 */
public class DataQueue: Server
{
	/// The filename to prepend to the running queue position number.
	static var prefix = "QueuedResource-"
	
	/// The file extension, likely "json".
	static var fileExtension = "json"
	
	/// The absolute path to the receiver's queue directory; individual per the receiver's host.
	let queueDirectory: String
	
	/** The filename of a resource at the given queue position. */
	func fileNameForSequence(seq: Int) -> String {
		return "\(self.dynamicType.prefix)\(seq)".stringByAppendingPathExtension(self.dynamicType.fileExtension)!
	}
	
	var fileProtection: NSDataWritingOptions {
		return NSDataWritingOptions.DataWritingFileProtectionCompleteUnlessOpen
	}
	
	override public init(baseURL: NSURL, auth: OAuth2JSON?) {
		if let dir = NSFileManager.defaultManager().chip_appLibraryDirectory() {
			if let host = baseURL.host {
				queueDirectory = dir.stringByAppendingPathComponent("DataQueue").stringByAppendingPathComponent(host)
			}
			else {
				fatalError("DataQueue: Cannot initialize without host in baseURL")
			}
		}
		else {
			fatalError("DataQueue: Failed to determine App Library Directory")
		}
		super.init(baseURL: baseURL, auth: auth)
	}
	
	
	// MARK: - Queue Directory
	
	var currentlyDequeueing: QueuedResource?
	
	/** Checks if the directory for queued files exists on disk, creating them and adjusting the file protection status if necessary. */
	func ensureHasDirectory() {
		let manager = NSFileManager.defaultManager()
		
		var error: NSError?
		var isDir: ObjCBool = true
		if !manager.fileExistsAtPath(queueDirectory, isDirectory: &isDir) || !isDir {
			if !manager.createDirectoryAtPath(queueDirectory, withIntermediateDirectories: true, attributes: nil, error: &error) {
				fatalError("DataQueue: Failed to create queue directory: \(error!)")
			}
		}
	}
	
	/** Looks at all resources in the queue and returns the lowest and highest position, if any. */
	public func currentQueueRange(manager: NSFileManager) -> (min: Int, max: Int)? {
		var myMin: Int?
		var myMax: Int?
		
		if let files = manager.contentsOfDirectoryAtPath(queueDirectory, error: nil) {
			for anyFile in files {
				if let file = anyFile as? NSString {
					var pure = file.stringByReplacingOccurrencesOfString(self.dynamicType.prefix, withString: "").stringByDeletingPathExtension as NSString
					myMin = min(myMin ?? pure.integerValue, pure.integerValue)
					myMax = max(myMax ?? pure.integerValue, pure.integerValue)
				}
			}
		}
		
		return (nil != myMin) ? (min: myMin!, max: myMax!) : nil
	}
	
	
	// MARK: - Queue Management
	
	/**
	    Enqueues the given resource.
	
	    :param: resource The FHIR Resource to enqueue
	 */
	public func enqueueResource(resource: Resource) {
		ensureHasDirectory()
		
		// get next sequence number
		var seq = currentQueueRange(NSFileManager())?.max ?? 0
		seq++
		
		// store new resoure to queue
		let path = queueDirectory.stringByAppendingPathComponent(fileNameForSequence(seq))
		var error: NSError?
		if let data = NSJSONSerialization.dataWithJSONObject(resource.asJSON(), options: nil, error: &error) {
			if data.writeToFile(path, options: fileProtection, error: &error) {
				chip_logIfDebug("Enqueued resource at \(path)")
			}
			else {
				chip_logIfDebug("Failed to write: \(error!)")
			}
		}
		else {
			chip_logIfDebug("Failed to serialize JSON: \(error!)")
		}
	}
	
	/** Convenience method for internal use; POST requests should be DataRequests so this should never fail. */
	func enqueueResourceInHandler(handler: FHIRServerRequestHandler) {
		if let resource = (handler as? FHIRServerDataRequestHandler)?.resource as? Resource {
			self.enqueueResource(resource)
		}
	}
	
	/** Starts flushing the queue, oldest resources first, until no more resources are enqueued or an error occurs. */
	public func flush(callback: ((error: NSError?) -> Void)) {
		dequeueFirst { [weak self] didDequeue, error in
			if let error = error {
				callback(error: error)
			}
			else if didDequeue {
				if let this = self {
					this.flush(callback)
				}
				else {
					callback(error: chip_genErrorDataQueue("Flush halted", code: 99))
				}
			}
			else {
				callback(error: nil)
			}
		}
	}
	
	/**
	    Looks and deserializes the first resource in the queue, then issues a `create` command to POST it to the server.
	
	    :param: callback The callback to call. "didDequeue" is true if the resource was successfully dequeued. "error" is nil on success or
	        if there was no file to dequeue (in which case _didDequeue_ would be false)
	 */
	public func dequeueFirst(callback: ((didDequeue: Bool, error: NSError?) -> Void)) {
		if nil != currentlyDequeueing {
			chip_logIfDebug("Already dequeueing")
			callback(didDequeue: false, error: nil)
			return
		}
		
		if let first = firstInQueue() {
			chip_logIfDebug("Dequeueing first in queue: \(first.path)")
			var error: NSError?
			if first.readFromFile(&error) {
				currentlyDequeueing = first
				first.resource!.id = nil
				first.resource!.create(self) { cError in
					if nil == cError {
						self.clearCurrentlyDequeueing()
					}
					callback(didDequeue: (nil == cError), error: cError)
				}
			}
			else {
				chip_logIfDebug("Failed to read resource data: \(error)")
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
		if let resource = currentlyDequeueing {
			if let path = resource.path {
				let manager = NSFileManager()
				var error: NSError?
				if manager.removeItemAtPath(path, error: &error) {
					currentlyDequeueing = nil
				}
				else {
					// TODO: figure out what to do
					chip_logIfDebug("Failed to remove queued resource \(path)")
				}
			}
		}
	}
	
	/**
	    Returns the first resource in the queue, but **only** if it is readable.
	 */
	final func firstInQueue() -> QueuedResource? {
		let manager = NSFileManager()
		if let var first = currentQueueRange(manager)?.min {
			let path = queueDirectory.stringByAppendingPathComponent(fileNameForSequence(first))
			if manager.isReadableFileAtPath(path) {
				return QueuedResource(path: path)
			}
			chip_logIfDebug("Have file in queue but it is not readable, waiting for next call")
		}
		return nil
	}
	
	
	// MARK: - URL Session
	
	override public func performPreparedRequest<R : FHIRServerRequestHandler>(request: NSMutableURLRequest, handler: R, callback: ((response: R.ResponseType) -> Void)) {
		if "POST" == request.HTTPMethod {
			// Note: can NOT use a completion block with a background session: will crash, must use delegate
			
			// are we currently dequeueing the resource we're trying to POST (and hence inside a `flush` call)?
			if let dequeueing = currentlyDequeueing?.resource,
				let resource = (handler as? FHIRServerDataRequestHandler)?.resource as? Resource where dequeueing === resource {
				
				super.performPreparedRequest(request, handler: handler, callback: callback)
			}
			
			// nope; ensure the queue is flushed, then perform the original POST
			else {
				self.flush() { error in
					if let error = error {
						self.enqueueResourceInHandler(handler)
						
						let response = R.ResponseType(notSentBecause: error)
						callback(response: response)
					}
					else {
						super.performPreparedRequest(request, handler: handler) { response in
							if nil != response.error {
								self.enqueueResourceInHandler(handler)
							}
							callback(response: response)
						}
					}
				}
			}
		}
		else {
			super.performPreparedRequest(request, handler: handler, callback: callback)
		}
	}
}


/**
    Convenience function to create an NSError in our dataqueue error domain.
 */
public func chip_genErrorDataQueue(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPDataQueueErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

