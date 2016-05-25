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

import SMART



public enum MotionActivityInterpretation: Int {
	case Unknown = 0
	
	// Sleeping "activity" is any activity of "stationary" that's longer than 3 hours.
	case Sleeping
	
	// Stationary.
	case Stationary
	
	// Likely driving a car or similar.
	case Automotive
	
	// Core Motion reports walking activity with low confidence.
	case PossiblyWalking
	
	// Core Motion reports walking activity with medium or high confidence.
	case Walking
	
	// Core Motion reports running activity with low confidence.
	case PossiblyRunning
	
	// Core Motion reports running activity with medium or high confidence.
	case Running
	
	// We're cycling.
	case Cycling
}


/**
Contains information about activity duration of a given type.
*/
public class MotionActivityDuration {
	
	public let type: MotionActivityInterpretation
	
	public let duration: Duration
	
	public init(type: MotionActivityInterpretation, duration: Duration) {
		self.type = type
		self.duration = duration
	}
	
	
	// MARK: - Helper
	
	public var identifier: String {
		switch type {
		case .Sleeping:
			return "sleeping"
		case .Stationary:
			return "stationary"
		case .Automotive:
			return "driving"
		case .PossiblyWalking:
			return "possibly walking"
		case .Walking:
			return "walking"
		case .PossiblyRunning:
			return "possibly running"
		case .Running:
			return "running"
		case .Cycling:
			return "cycling"
		case .Unknown:
			return "unknown"
		}
	}
	
	public var name: String {
		switch type {
		case .Sleeping:
			return "Sleeping"
		case .Stationary:
			return "Stationary"
		case .Automotive:
			return "Driving"
		case .PossiblyWalking:
			return "Walking?"
		case .Walking:
			return "Walking"
		case .PossiblyRunning:
			return "Running?"
		case .Running:
			return "Running"
		case .Cycling:
			return "Cycling"
		case .Unknown:
			return "unknown"
		}
	}
	
	public var preferredPosition: Int {
		switch type {
		case .Sleeping:
			return 0
		case .Stationary:
			return 2
		case .Automotive:
			return 10
		case .PossiblyWalking:
			return 100
		case .Walking:
			return 101
		case .PossiblyRunning:
			return 110
		case .Running:
			return 111
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
		case .PossiblyWalking:
			hue = 0.33
		case .Walking:
			hue = 0.4
		case .PossiblyRunning:
			hue = 0.0
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


