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
	case unknown = "unknown"
	
	/// Sleeping "activity" is derived from a "stationary" activity longer than 3 hours.
	case sleeping = "sleeping"
	
	/// Stationary.
	case stationary = "stationary"
	
	/// Likely driving a car or similar.
	case automotive = "driving"
	
	/// Core Motion reports walking activity.
	case walking = "walking"
	
	/// Core Motion reports running activity.
	case running = "running"
	
	/// We're cycling.
	case cycling = "cycling"
	
	
	/// The name of the interpretation to be shown to humans.
	public var humanName: String {
		switch self {
		case .sleeping:
			return "Sleeping"
		case .stationary:
			return "Stationary"
		case .automotive:
			return "Driving"
		case .walking:
			return "Walking"
		case .running:
			return "Running"
		case .cycling:
			return "Cycling"
		case .unknown:
			return "unknown"
		}
	}
}


/**
A CoreMotionActivity subclass that also has an end date, for easier use for user presentation.
*/
open class InterpretedCoreMotionActivity: CoreMotionActivity {
	
	/// When the receiver ended.
	open var endDate: Date
	
	/// The interpretation for this particular activity.
	open var interpretation = CoreMotionActivityInterpretation.unknown
	
	
	public init(start: Date, activity: CoreMotionActivityType, confidence: CMMotionActivityConfidence, end: Date) {
		endDate = end
		super.init(start: start, activity: activity, confidence: confidence)
	}
	
	public convenience init(start: Double, activity inActivity: Int, confidence inConfidence: Int, end: Double) {
		let startDate = Date(timeIntervalSinceReferenceDate: start)
		let activity = CoreMotionActivityType(rawValue: inActivity)
		let confidence = CMMotionActivityConfidence(rawValue: inConfidence) ?? .low
		let endDate = Date(timeIntervalSinceReferenceDate: end)
		self.init(start: startDate, activity: activity, confidence: confidence, end: endDate)
	}
}

