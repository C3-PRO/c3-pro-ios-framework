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
public class CoreMotionStandardActivityInterpreter: CoreMotionActivityInterpreter {
	
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
	public func preprocess(activities activities: [CMMotionActivity]) -> [CoreMotionActivity] {
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
	func preprocessedMotionActivity<T: CoreMotionActivity>(activity: T, followingAfter prev: T?) -> T? {
		
		// 1: skip unknown activities (skip if "unknown" = true (known unknown) as well as those without any true state (unknown unknown))
		if !activity.type.isSubsetOf(.Unknown) {
			
			// 2: join same activities
			if let prev = prev where prev.type.isSubsetOf(activity.type) && activity.type.isSubsetOf(prev.type) {
				prev.confidence = max(prev.confidence, activity.confidence)
			}
				
				// 3: join automotive activities
			else if let prev = prev where prev.type.contains(.Automotive) && activity.type.contains(.Automotive) {
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
	public func interpret(activities activities: [InterpretedCoreMotionActivity]) -> [InterpretedCoreMotionActivity] {
		var prev: InterpretedCoreMotionActivity?
		for i in 0..<activities.count {
			let activity = activities[i]
			let duration = activity.endDate.timeIntervalSinceDate(activity.startDate)
			
			// automotive < 5 minutes: stationary
			if activity.type.contains(.Automotive) && duration < 300.0 {
				activity.type.remove(.Automotive)
				activity.type.unionInPlace(.Stationary)
				activity.interpretation = .Automotive
			}
				
			// cycling < 2 minutes: running if prev/next is running, walking if prev/next is walking, stationary otherwise
			else if activity.type.contains(.Cycling) && duration < 120.0 {
				activity.type.remove(.Cycling)
				if let prev = prev where prev.type.contains(.Running) {
					activity.type.unionInPlace(.Running)
					activity.interpretation = .Running
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Running) {
					activity.type.unionInPlace(.Running)
					activity.interpretation = .Running
				}
				else if let prev = prev where prev.type.contains(.Walking) {
					activity.type.unionInPlace(.Walking)
					activity.interpretation = .Walking
				}
				else if activities.count > i+1 && activities[i+1].type.contains(.Walking) {
					activity.type.unionInPlace(.Walking)
					activity.interpretation = .Walking
				}
				else {
					activity.type.unionInPlace(.Stationary)
					activity.interpretation = .Stationary
				}
			}
			
			/*/ stationary < 1 minute, running or walking before and after: standing
			else if activity.type.contains(.Stationary) && duration < 60.0 {
			if let prev = prev where prev.isWalkingRunningCycling {
			}
			else if self.activities.count > i+1 && self.activities[i+1].isWalkingRunningCycling {
			}
			}	//	*/
			
			// no rule, interpret by picking `type`
			else {
				if activity.type.contains(.Cycling) {
					activity.interpretation = .Cycling
				}
				else if activity.type.contains(.Running) {
					activity.interpretation = .Running
				}
				else if activity.type.contains(.Walking) {
					activity.interpretation = .Walking
				}
				else if activity.type.contains(.Automotive) {
					activity.interpretation = .Automotive
				}
				else if activity.type.contains(.Stationary) {
					activity.interpretation = .Stationary
				}
				else {
					activity.interpretation = .Unknown
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
				if .Stationary == inter.interpretation {
					if NSCalendar.currentCalendar().components(.Hour, fromDate: inter.startDate, toDate: inter.endDate, options: []).hour >= 3 {
						inter.interpretation = .Sleeping
					}
				}
			}
		}
		return interpreted
	}
}

