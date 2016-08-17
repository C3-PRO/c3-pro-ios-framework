//
//  Foundation+C3-PRO.swift
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


extension Calendar {
	
	/**
	Returns an array of tuples, constituting from <-> to pairs, starting with all of yesterday and the 4 days before, then the 3 weeks
	before, then the 4 months before. Tuples contain:
	
	1. start date components
	2. end date components
	3. number of days in period
	4. name of period
	*/
	public func reverseProgressiveDateComponentsSinceToday() -> [(DateComponents, DateComponents, Int, String)] {
		let now = Date()
		let startComponents = dateComponents([.day, .weekday, .month, .year], from: now)
		
		var intervals = [(DateComponents, DateComponents, Int, String)]()
		
		// days
		var last = startComponents
		for i in 1...5 {
			var comps = DateComponents()
			comps.year = startComponents.year
			comps.month = startComponents.month
			comps.day = (startComponents.day ?? 30) - i
			let weekday = component(.weekday, from: date(from: comps)!) - 1		// weekdays are 1 (Sun) through 7 (Sat) in the Gregorian calendar
			intervals.append((comps, last, 1, shortWeekdaySymbols[weekday]))
			last = comps
		}
		
		// weeks
		var thisWeek = startComponents
		thisWeek.day! -= thisWeek.weekday!
		var week = startComponents
		week.day! -= week.weekday! + 7
		intervals.append((week, thisWeek, 7, "Last\nWeek"))
		last = week
		
		var weekBefore = week
		weekBefore.day! -= 7
		intervals.append((weekBefore, last, 7, "Week\nBfor"))
		last = weekBefore
		
//		var weekBeforeThat = weekBefore
//		weekBeforeThat.day -= 7
//		intervals.append((weekBeforeThat, last, 7, "Week"))
//		last = weekBeforeThat
		
		// months
		let currentMonth = date(from: last) ?? Date()
		let month1 = component(.month, from: date(from: week)!)
		let month2 = component(.month, from: currentMonth)
		var firstMonth = DateComponents()
		firstMonth.year = last.year
		firstMonth.month = month2
		firstMonth.day = 1
		if month1 == month2 {
			firstMonth.month! -= 1
		}
		let startMonth = date(from: firstMonth)!
		let rng = range(of: .day, in: .month, for: startMonth)!
		intervals.append((firstMonth, last, rng.upperBound - rng.lowerBound, shortMonthSymbols[component(.month, from: startMonth) - 1]))
		last = firstMonth
		
		for i in 1...3 {
			var comps = firstMonth
			comps.month! -= i
			let dt = date(from: comps)!
			let rng = range(of: .day, in: .month, for: dt)!
			intervals.append((comps, last, rng.upperBound - rng.lowerBound, shortMonthSymbols[component(.month, from: dt) - 1]))
			last = comps
		}
		
		return intervals
	}
	
	
	/**
	Returns an array of tuples, constituting from <-> to pairs, of the past 7 days. Tuples contain:
	
	1. start date components
	2. end date components
	3. number of days in period
	4. name of period
	*/
	public func pastSevenDays() -> [(DateComponents, DateComponents, Int, String)] {
		let now = Date()
		let startComponents = dateComponents([.hour, .day, .month, .year], from: now)
		var intervals = [(DateComponents, DateComponents, Int, String)]()
		
		// days
		var last = startComponents
		for i in 0..<7 {
			var comps = DateComponents()
			comps.year = startComponents.year
			comps.month = startComponents.month
			comps.day = startComponents.day! - i
			let weekday = component(.weekday, from: date(from: comps)!) - 1		// weekdays are 1 (Sun) through 7 (Sat) in the Gregorian calendar
			intervals.append((comps, last, 1, shortWeekdaySymbols[weekday]))
			last = comps
		}
		
		return intervals
	}
}

