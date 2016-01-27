//
//  QueuedResource.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/28/15.
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
				resource = Resource.instantiateFrom(json, owner: nil) as? Resource
				if nil != resource {
					return
				}
				throw FHIRError.ResourceFailedToInstantiate(NSString(data: data, encoding: NSUTF8StringEncoding) as? String ?? "No data")
			}
		}
		throw FHIRError.ResourceLocationUnknown
	}
}

