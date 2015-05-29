//
//  QueuedResource.swift
//  ResearchCHIP
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
	
		:returns: True if the resource was successfully instantiated, false otherwise
	 */
	func readFromFile(error: NSErrorPointer) -> Bool {
		if let path = path {
			if let data = NSData(contentsOfFile: path, options: nil, error: error) {
				if let json = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: error) as? FHIRJSON {
					resource = FHIRElement.instantiateFrom(json, owner: nil) as? Resource
					return nil != resource
				}
			}
		}
		return false
	}
}

