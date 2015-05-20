//
//  CHIPExtensions.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 4/27/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation


extension String
{
	func chip_stripMultipleSpaces() -> String {
		if let regEx = NSRegularExpression(pattern: " +", options: nil, error: nil) {
			return regEx.stringByReplacingMatchesInString(self, options: nil, range: NSMakeRange(0, count(self)), withTemplate: " ")
		}
		return self
	}
}


func chip_logIfDebug(@autoclosure message: () -> String, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
	#if DEBUG
	println("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}
