//
//  FoundationExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/27/15.
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


extension String {
	
	/**
	Concatenate multiple spaces into one.
	
	- returns: The receiver with multiple spaces stripped
	*/
	func c3_stripMultipleSpaces() -> String {
		do {
			let regEx = try NSRegularExpression(pattern: " +", options: [])
			return regEx.stringByReplacingMatches(in: self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: " ")
		}
		catch {
		}
		return self
	}
}


extension FileManager {
	
	/**
	Return the path to the app's library directory.
	
	- returns: The path to the app library
	*/
	public func c3_appLibraryDirectory() throws -> String {
		let paths = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .userDomainMask, true)
		if let first = paths.first {
			return first
		}
		throw C3Error.appLibraryDirectoryNotPresent
	}
}

