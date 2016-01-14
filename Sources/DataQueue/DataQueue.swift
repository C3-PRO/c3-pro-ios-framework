//
//  DataQueue.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/28/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


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
	
	/// The manager for the data queue
	var queueManager: DataQueueManager!
	
	/** The filename of a resource at the given queue position. */
	func fileNameForSequence(seq: Int) -> String {
		return ("\(self.dynamicType.prefix)\(seq)" as NSString).stringByAppendingPathExtension(self.dynamicType.fileExtension)!
	}
	
	var fileProtection: NSDataWritingOptions {
		return NSDataWritingOptions.DataWritingFileProtectionCompleteUnlessOpen
	}
	
	public required init(baseURL: NSURL, auth: OAuth2JSON?) {
		super.init(baseURL: baseURL, auth: auth)
		let dir = try! NSFileManager.defaultManager().chip_appLibraryDirectory()
		if let host = baseURL.host {
			let full = ((dir as NSString).stringByAppendingPathComponent("DataQueue") as NSString).stringByAppendingPathComponent(host)
			queueManager = DataQueueManager(fhirServer: self, directory: full)
		}
		else {
			fatalError("DataQueue: Cannot initialize without host in baseURL")
		}
	}
	
	
	// MARK: - Queue Manager
	
	/**
	    Enqueues the given resource.
	
	    - parameter resource: The FHIR Resource to enqueue
	 */
	public func enqueueResource(resource: Resource) {
		queueManager.enqueueResource(resource)
	}
	
	/** Starts flushing the queue, oldest resources first, until no more resources are enqueued or an error occurs. */
	public func flush(callback: ((error: ErrorType?) -> Void)) {
		queueManager.flush(callback)
	}
	
	
	// MARK: - URL Session
	
	override public func performPreparedRequest<R : FHIRServerRequestHandler>(request: NSMutableURLRequest, handler: R, callback: ((response: FHIRServerResponse) -> Void)) {
		if .POST == handler.type || .PUT == handler.type {
			// Note: can NOT use a completion block with a background session: will crash, must use delegate
			
			// are we currently dequeueing the resource we're trying to POST (and hence inside a `flush` call)?
			if let resource = handler.resource as? Resource where queueManager.isDequeueing(resource) {
				super.performPreparedRequest(request, handler: handler, callback: callback)
			}
			
			// nope; ensure the queue is flushed, then perform the original POST
			else {
				queueManager.flush() { error in
					if let error = error {
						self.queueManager.enqueueResourceInHandler(handler)
						
						let response = R.ResponseType.init(error: error)
						callback(response: response)
					}
					else {
						super.performPreparedRequest(request, handler: handler) { response in
							if nil != response.error {
								self.queueManager.enqueueResourceInHandler(handler)
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

