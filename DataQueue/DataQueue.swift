//
//  DataQueue.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 5/28/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public class DataQueue: Server
{
	static var prefix = "QueuedFile-"
	static var fileExtension = "json"
	
	func fileNameForSequence(seq: Int) -> String {
		return "\(self.dynamicType.prefix)\(seq)".stringByAppendingPathExtension(self.dynamicType.fileExtension)!
	}
	
	var fileProtection: NSDataWritingOptions {
		return NSDataWritingOptions.DataWritingFileProtectionCompleteUnlessOpen
	}
	
	var fileAttributes: [String: String] {
		return [NSFileProtectionKey: NSFileProtectionCompleteUnlessOpen]
	}
	
	override public init(baseURL: NSURL, auth: OAuth2JSON?) {
		super.init(baseURL: baseURL, auth: auth)
	}
	
	
	// MARK: - Queue Directory
	
	var currentlyDequeueing: QueuedResource?
	
	func queueDirectory() -> String {
		if let dir = NSFileManager.defaultManager().chip_appLibraryDirectory() {
			return dir.stringByAppendingPathComponent("DataQueue")
		}
		fatalError("DataQueue: Failed to determine App Library Directory")
	}
	
	func ensureHasDirectory() {
		let manager = NSFileManager.defaultManager()
		let queueDir = queueDirectory()
		
		var error: NSError?
		var isDir: ObjCBool = true
		if !manager.fileExistsAtPath(queueDir, isDirectory: &isDir) || !isDir {
			if !manager.createDirectoryAtPath(queueDir, withIntermediateDirectories: true, attributes: fileAttributes, error: &error) {
				fatalError("DataQueue: Failed to create queue directory: \(error!)")
			}
		}
		else {
			if !manager.setAttributes(fileAttributes, ofItemAtPath: queueDir, error: &error) {
				fatalError("DataQueue: Failed to set attributes on queue directory: \(error!)")
			}
		}
	}
	
	public func currentQueueRange(manager: NSFileManager) -> (min: Int, max: Int)? {
		let directory = queueDirectory()
		var myMin: Int?
		var myMax: Int?
		
		if let files = manager.contentsOfDirectoryAtPath(directory, error: nil) {
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
	
	public func enqueueResource(resource: FHIRResource) {
		ensureHasDirectory()
		let manager = NSFileManager()
		
		// get next sequence number
		var seq = currentQueueRange(manager)?.max ?? 0
		seq++
		
		// store new resoure to queue
		let path = queueDirectory().stringByAppendingPathComponent(fileNameForSequence(seq))
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
			chip_logIfDebug("Failed to create JSON: \(error!)")
		}
	}
	
	public func dequeueFirst(callback: ((didDequeue: Bool, error: NSError?) -> Void)) {
		if nil != currentlyDequeueing {
			chip_logIfDebug("Already holding on to a queued resource")
			callback(didDequeue: false, error: nil)
			return
		}
		
		if let first = firstInQueue() {
			chip_logIfDebug("Dequeueing first in queue: \(first.path)")
			var error: NSError?
			if first.readFromFile(&error) {
				currentlyDequeueing = first
				first.resource!.create(self) { cError in
					if nil == cError {
						self.clearCurrentlyDequeueing()
					}
					callback(didDequeue: (nil == cError), error: cError)
				}
			}
			else {
				chip_logIfDebug("Failed to read resource data: \(error)")
				// TODO: figure out what to do (file should be readable)
				callback(didDequeue: false, error: nil)
			}
		}
		else {
			callback(didDequeue: false, error: nil)
		}
	}
	
	public func clearCurrentlyDequeueing() {
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
			let path = queueDirectory().stringByAppendingPathComponent(fileNameForSequence(first))
			if manager.isReadableFileAtPath(path) {
				return QueuedResource(path: path)
			}
			chip_logIfDebug("Have file in queue but it is not readable, waiting for next call")
		}
		return nil
	}
	
	
	// MARK: - URL Session
	
	var _backgroundURLSession: NSURLSession?
	
	var backgroundURLSession: NSURLSession {
		if nil == _backgroundURLSession {
			let config = NSURLSessionConfiguration.backgroundSessionConfigurationWithIdentifier("org.chip.ResearchCHIP.backgroundURLSession")
			_backgroundURLSession = NSURLSession(configuration: config, delegate: sessionDelegate, delegateQueue: nil)
		}
		return _backgroundURLSession!
	}
	
	override public func performPreparedRequest<R : FHIRServerRequestHandler>(request: NSMutableURLRequest, handler: R, callback: ((response: R.ResponseType) -> Void)) {
		if "POST" == request.HTTPMethod {
			super.performPreparedRequest(request, withSession: backgroundURLSession, handler: handler, callback: callback)
		}
		else {
			super.performPreparedRequest(request, handler: handler, callback: callback)
		}
	}
}

