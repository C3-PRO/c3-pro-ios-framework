//
//  MotionActivity.swift
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
import SMART



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


/**
Contains information about activity duration of a given type.
*/
public struct CoreMotionActivitySum {
	
	public let type: CoreMotionActivityInterpretation
	
	public let duration: Duration
	
	public init(type: CoreMotionActivityInterpretation, duration: Duration) {
		self.type = type
		self.duration = duration
	}
	
	
	// MARK: - Helper
	
	public var preferredPosition: Int {
		switch type {
		case .Sleeping:
			return 0
		case .Stationary:
			return 4
		case .Automotive:
			return 10
		case .Walking:
			return 100
		case .Running:
			return 120
		case .Cycling:
			return 200
		case .Unknown:
			return 999
		}
	}
	
	public func preferredColorComponentsHSB() -> (hue: Float, saturation: Float, brightness: Float) {
		var hue: Float = 0.0
		var sat: Float = 0.7
		var bright: Float = 0.94
		switch type {
		case .Sleeping:
			hue = 0.0
			sat = 0.0
			bright = 0.85
		case .Stationary:
			hue = 0.54
		case .Automotive:
			hue = 0.61
		case .Walking:
			hue = 0.4
		case .Running:
			hue = 0.04
		case .Cycling:
			hue = 0.1
		case .Unknown:
			hue = 0.0
			sat = 0.0
			bright = 0.7
		}
		return (hue: hue, saturation: sat, brightness: bright)
	}
}


