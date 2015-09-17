//
//  FoundationExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/27/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation


extension String
{
	func chip_stripMultipleSpaces() -> String {
		do {
			let regEx = try NSRegularExpression(pattern: " +", options: [])
			return regEx.stringByReplacingMatchesInString(self, options: [], range: NSMakeRange(0, self.characters.count), withTemplate: " ")
		} catch _ {
		}
		return self
	}
}


public extension NSFileManager
{
	public func chip_appLibraryDirectory() -> String? {
		let paths = NSSearchPathForDirectoriesInDomains(.LibraryDirectory, .UserDomainMask, true)
		return (paths.count > 0) ? paths[0] : nil
	}
}


func chip_logIfDebug(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
	#if DEBUG
	print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}

func chip_warn(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
	print("[\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

