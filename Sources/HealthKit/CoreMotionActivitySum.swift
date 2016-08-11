//
//  CoreMotionActivitySum.swift
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
import SMART


/**
Contains information about activity duration of a given type.
*/
public struct CoreMotionActivitySum: CustomStringConvertible, CustomDebugStringConvertible {
	
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
	
	
	// MARK: - String Convertible
	
	public var description: String {
		return "<\(String(self.dynamicType))> “\(type.rawValue)” of \(duration.value ?? NSDecimalNumber.zero) \(duration.unit ?? "")"
	}
	
	public var debugDescription: String {
		return description
	}
}


