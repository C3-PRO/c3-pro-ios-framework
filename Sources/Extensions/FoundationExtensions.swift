//
//  FoundationExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/27/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation


extension String {
	func chip_stripMultipleSpaces() -> String {
		do {
			let regEx = try NSRegularExpression(pattern: " +", options: [])
			return regEx.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: " ")
		} catch {
		}
		return self
	}
}


public extension NSFileManager {
	public func chip_appLibraryDirectory() throws -> String {
		let paths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
		if let first = paths.first {
			return first
		}
		throw C3Error.AppLibraryDirectoryNotPresent
	}
}

