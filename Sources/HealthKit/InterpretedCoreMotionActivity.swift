//
//  InterpretedCoreMotionActivity.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 24/05/16.
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

import Foundation
import CoreMotion


/**
Interpretation of core motion activity, as derived from looking at activities over time.
*/
public enum CoreMotionActivityInterpretation: String {
	case Unknown = "unknown"
	
	/// Sleeping "activity" is derived from a "stationary" activity longer than 3 hours.
	case Sleeping = "sleeping"
	
	/// Stationary.
	case Stationary = "stationary"
	
	/// Likely driving a car or similar.
	case Automotive = "driving"
	
	/// Core Motion reports walking activity.
	case Walking = "walking"
	
	/// Core Motion reports running activity.
	case Running = "running"
	
	/// We're cycling.
	case Cycling = "cycling"
	
	
	/// The name of the interpretation to be shown to humans.
	public var humanName: String {
		switch self {
		case .Sleeping:
			return "Sleeping"
		case .Stationary:
			return "Stationary"
		case .Automotive:
			return "Driving"
		case .Walking:
			return "Walking"
		case .Running:
			return "Running"
		case .Cycling:
			return "Cycling"
		case .Unknown:
			return "unknown"
		}
	}
}


/**
A CoreMotionActivity subclass that also has an end date, for easier use for user presentation.
*/
public class InterpretedCoreMotionActivity: CoreMotionActivity {
	
	/// When the receiver ended.
	public var endDate: NSDate
	
	/// The interpretation for this particular activity.
	public var interpretation = CoreMotionActivityInterpretation.Unknown
	
	
	public init(start: NSDate, activity: CoreMotionActivityType, confidence: CMMotionActivityConfidence, end: NSDate) {
		endDate = end
		super.init(start: start, activity: activity, confidence: confidence)
	}
	
	public convenience init(start: Double, activity inActivity: Int, confidence inConfidence: Int, end: Double) {
		let startDate = NSDate(timeIntervalSinceReferenceDate: start)
		let activity = CoreMotionActivityType(rawValue: inActivity)
		let confidence = CMMotionActivityConfidence(rawValue: inConfidence) ?? .Low
		let endDate = NSDate(timeIntervalSinceReferenceDate: end)
		self.init(start: startDate, activity: activity, confidence: confidence, end: endDate)
	}
}

