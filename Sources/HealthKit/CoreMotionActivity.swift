//
//  CoreMotionActivity.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 25/05/16.
//  Copyright © 2016 University Hospital Zurich. All rights reserved.
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

import CoreMotion


/**
Bitmask for core motion activity types, mapping directly to what's available in CMMotionActivity.
*/
public struct CoreMotionActivityType: OptionSet {
	public let rawValue: Int
	public init(rawValue: Int) {
		self.rawValue = rawValue
	}
	
	/// None of the activity types or "unknown" was set to true.
	static let Unknown    = CoreMotionActivityType(rawValue: 1 << 0)
	
	/// The activitiy's "stationary" flag was on.
	static let Stationary = CoreMotionActivityType(rawValue: 1 << 1)
	
	/// The activitiy's "automotive" flag was on.
	static let Automotive = CoreMotionActivityType(rawValue: 1 << 2)
	
	/// The activitiy's "walking" flag was on.
	static let Walking    = CoreMotionActivityType(rawValue: 1 << 3)
	
	/// The activitiy's "running" flag was on.
	static let Running    = CoreMotionActivityType(rawValue: 1 << 4)
	
	/// The activitiy's "cycling" flag was on. Remember WWDC14, this is likely only correct when phone is worn on the arm.
	static let Cycling    = CoreMotionActivityType(rawValue: 1 << 5)
}


/**
Class representing a CMMotionActivity.
*/
open class CoreMotionActivity {
	
	/// The type(s) the activity represented.
	open var type: CoreMotionActivityType
	
	/// When the receiver started.
	open var startDate: Date
	
	/// The confidence in the activity determination.
	open var confidence: CMMotionActivityConfidence
	
	
	public init(start: Date, activity: CoreMotionActivityType, confidence inConfidence: CMMotionActivityConfidence) {
		type = activity
		startDate = start
		confidence = inConfidence
	}
	
	public convenience init(activity: CMMotionActivity) {
		var typ: CoreMotionActivityType = .Unknown
		if activity.stationary {
			typ.insert(.Stationary)
			typ.remove(.Unknown)
		}
		if activity.automotive {
			typ.insert(.Automotive)
			typ.remove(.Unknown)
		}
		if activity.walking {
			typ.insert(.Walking)
			typ.remove(.Unknown)
		}
		if activity.running {
			typ.insert(.Running)
			typ.remove(.Unknown)
		}
		if activity.cycling {
			typ.insert(.Cycling)
			typ.remove(.Unknown)
		}
		self.init(start: activity.startDate, activity: typ, confidence: activity.confidence)
	}
}


extension CMMotionActivityConfidence: Equatable {}
public func ==(lhs: CMMotionActivityConfidence, rhs: CMMotionActivityConfidence) -> Bool {
	return lhs.rawValue == rhs.rawValue
}


extension CMMotionActivityConfidence: Comparable {}
public func <(lhs: CMMotionActivityConfidence, rhs: CMMotionActivityConfidence) -> Bool {
	return lhs.rawValue < rhs.rawValue
}

