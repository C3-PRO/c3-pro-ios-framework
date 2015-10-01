//
//  QueuedResource.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/28/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
    Holds on to a FHIR resource, enqueued in a DataQueue.
 */
public class QueuedResource
{
	public var path: String?
	
	public var resource: Resource?
	
	public var date: NSDate?
	
	public init() {
	}
	
	public init(path: String) {
		self.path = path
	}
	
	
	/**
	    If path is known, reads the data from file, interprets as JSON and instantiates the receiver's resource.
	
		- returns: True if the resource was successfully instantiated, false otherwise
	 */
	func readFromFile() throws {
		if let path = path {
			do {
				let data = try NSData(contentsOfFile: path, options: [])
				let json = try NSJSONSerialization.JSONObjectWithData(data, options: []) as? FHIRJSON
				resource = FHIRElement.instantiateFrom(json, owner: nil) as? Resource
				if nil != resource {
					return
				}
				throw NSError(domain: "CHIPQueuedResource", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to instantiate from json"])
			}
		}
		throw NSError(domain: "CHIPQueuedResource", code: 0, userInfo: [NSLocalizedDescriptionKey: "No path, cannot read from file"])
	}
}

