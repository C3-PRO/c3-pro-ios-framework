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
Class to represent a FHIR resource enqueued in a `DataQueue`.
*/
open class QueuedResource {
	
	/// The fath to the resource.
	open let path: String
	
	/// The actual resource instance.
	open var resource: Resource?
	
	
	/**
	Initialize a queued resource from a given path.
	
	- parameter path: The path the resource lives at
	*/
	public init(path: String) {
		self.path = path
	}
	
	
	/**
	If path is known, reads the data from file, interprets as JSON and instantiates the receiver's resource.
	
	- returns: True if the resource was successfully instantiated, false otherwise
	*/
	func readFromFile() throws {
		let data = try Data(contentsOf: URL(fileURLWithPath: path), options: [])
		let json = try JSONSerialization.jsonObject(with: data, options: []) as? FHIRJSON
		resource = Resource.instantiate(fromJSON: json, owner: nil) as? Resource
		if nil != resource {
			return
		}
		throw FHIRError.resourceFailedToInstantiate(String(data: data, encoding: String.Encoding.utf8) ?? "No data")
	}
}

