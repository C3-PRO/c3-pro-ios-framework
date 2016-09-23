//
//  CoreMotionStandardActivityInterpreter.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 19/07/16.
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
Standard implementation of a core motion activity preprocessor and interpreter.

See `preprocess(activities:)` and `interpret(activities:)` for details on the logic performed.
*/
open class CoreMotionStandardActivityInterpreter: CoreMotionActivityInterpreter {
	
	public init() {
	}
	
	
	// MARK: - CoreMotionActivityInterpreter
	
	/**
	Preprocesses raw motion activities before they are dumped to SQLite. See the Motion Tracking talk from WWDC14 for a detailed look at
	how this stuff works: https://developer.apple.com/videos/play/wwdc2014/612/
	
	1. all unknown activities are discarded
	2. adjacent activities with same type(s), ignoring their confidence, are joined together and the highest confidence is retained; this
	means that activities that had unknown activities interspersed are joined together and also span the time of the unknown period
	3. adjacent "automotive" activities are joined even if they have additional types (typically "stationary"); highest confidence is
	retained and their types are union-ed
	
	- parameter activities: The activities to preprocess
	- returns: Preprocessed and packaged motion activities
	*/
	open func preprocess(activities: [CMMotionActivity]) -> [CoreMotionActivity] {
		var samples = [CoreMotionActivity]()
		for cmactivity in activities {
			let activity = CoreMotionActivity(activity: cmactivity)
			if let processed = preprocessedMotionActivity(activity, followingAfter: samples.last) {
				samples.append(processed)
			}
		}
		return samples
	}
	
	/**
	Internal method to apply preprocessing both before archiving as well as for interpretation during retrieval.
	
	See `preprocess(activities:)` for the rules being applied.
	
	- parameter activity:       The activity to evaluate
	- parameter followingAfter: The activity preceding `activity`, if any - may be modified
	- returns:                  An interpreted activity to be collected by the caller; if nil is returned the activity has been filtered
	*/
	func preprocessedMotionActivity<T: CoreMotionActivity>(_ activity: T, followingAfter prev: T?) -> T? {
		
		// 1: skip unknown activities (skip if "unknown" = true (known unknown) as well as those without any true state (unknown unknown))
		if !activity.type.isSubset(of: .Unknown) {
			
			// 2: join same activities
			if let prev = prev, prev.type.isSubset(of: activity.type) && activity.type.isSubset(of: prev.type) {
				prev.confidence = max(prev.confidence, activity.confidence)
			}
				
				// 3: join automotive activities
			else if let prev = prev, prev.type.contains(.Automotive) && activity.type.contains(.Automotive) {
				prev.type = prev.type.union(activity.type)
				prev.confidence = max(prev.confidence, activity.confidence)
			}
			else {
				return activity
			}
		}
		return nil
	}
	
	/**
	Our implementation of the core motion activity interpreter. It runs these interpretation rules:
	
	- automotive < 5 minutes: stationary
	- cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
	- walking < 1 minute, stationary prev and next, low confidence: stationary
	- stationary > 3 hours: sleeping
	- IDEA: stationary < 1 minute, running or walking before and after: standing
	
	- parameter activities: The activities to interpret
	- returns:              An array of interpreted activities
	*/
	open func interpret(activities: [InterpretedCoreMotionActivity]) -> [InterpretedCoreMotionActivity] {
		var prev: InterpretedCoreMotionActivity?
		for i in 0..<activities.count {
			let activity = activities[i]
			let duration = activity.endDate.timeIntervalSince(activity.startDate as Date)
			
			// automotive < 5 minutes: stationary
			if activity.type.contains(.Automotive) && duration < 300.0 {
				activity.type.remove(.Automotive)
				activity.type.formUnion(.Stationary)
				activity.interpretation = .automotive
			}
				
			// cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
			else if activity.type.contains(.Cycling) && duration < 120.0 {
				activity.type.remove(.Cycling)
				if let prev = prev, prev.type.contains(.Running) {
					activity.type.formUnion(.Running)
					activity.interpretation = .running
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Running) {
					activity.type.formUnion(.Running)
					activity.interpretation = .running
				}
				else if let prev = prev, prev.type.contains(.Walking) {
					activity.type.formUnion(.Walking)
					activity.interpretation = .walking
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Walking) {
					activity.type.formUnion(.Walking)
					activity.interpretation = .walking
				}
				else {
					activity.type.formUnion(.Stationary)
					activity.interpretation = .stationary
				}
			}
			
			/*/ stationary < 1 minute, running or walking before and after: standing
			else if activity.type.contains(.Stationary) && duration < 60.0 {
			if let prev = prev, prev.isWalkingRunningCycling {
			}
			else if self.activities.count > i+1 && self.activities[i+1].isWalkingRunningCycling {
			}
			}	//	*/
			
			// no rule, interpret by picking `type`
			else {
				if activity.type.contains(.Cycling) {
					activity.interpretation = .cycling
				}
				else if activity.type.contains(.Running) {
					activity.interpretation = .running
				}
				else if activity.type.contains(.Walking) {
					activity.interpretation = .walking
				}
				else if activity.type.contains(.Automotive) {
					activity.interpretation = .automotive
				}
				else if activity.type.contains(.Stationary) {
					activity.interpretation = .stationary
				}
				else {
					activity.interpretation = .unknown
				}
			}
			
			prev = activity
		}
		
		// concatenate same (using the same preprocessing algo as when archiving since activities may have changed) and find sleep
		var interpreted = [InterpretedCoreMotionActivity]()
		for activity in activities {
			if let inter = preprocessedMotionActivity(activity, followingAfter: interpreted.last) {
				interpreted.append(inter)
				
				// is this sleep? Yes if stationary > 3 hours
				if .stationary == inter.interpretation {
					if Calendar.current.dateComponents([.hour], from: inter.startDate, to: inter.endDate).hour! >= 3 {
						inter.interpretation = .sleeping
					}
				}
			}
		}
		return interpreted
	}
}

