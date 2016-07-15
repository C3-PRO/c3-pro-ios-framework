//
//  HealthKitReporter.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 15/07/16.
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
import HealthKit
import SMART


/**
Convenience class querying HealthKit and CoreMotion for activity data.
*/
public class HealthKitReporter: ActivityReporter {
	
	lazy var healthStore = HKHealthStore()
	
	
	public init() {
	}
	
	
	// MARK: - Convenience Methods
	
	/**
	
	*/
	public func reportForActivityPeriod(startingAt start: NSDate, until: NSDate, callback: ((period: ActivityReportPeriod?, error: ErrorType?) -> Void)) {
		retrieveHealthKitActivityData(startingAt: start, until: until) { samples, error in
			
			// create the period
			let period = Period(json: nil)
			period.start = start.fhir_asDateTime()
			period.end = until.fhir_asDateTime()
			
			// Put all data into one ActivityData instance
			let report = ActivityReportPeriod(period: period)
			report.healthKitSamples = samples
			callback(period: report, error: error)
		}
	}
	
	
	// MARK: - HealthKit Access
	
	/**
	Samples activity data in HealthKit (steps, flights climbed and active energy) and returns one HKQuantitySample per type in a callback.
	*/
	public func retrieveHealthKitActivityData(startingAt start: NSDate, until: NSDate, callback: ((samples: [HKQuantitySample]?, error: ErrorType?) -> Void)) {
		if HKHealthStore.isHealthDataAvailable() {
			let queueGroup = dispatch_group_create()
			var quantities = [HKQuantitySample]()
			var errors = [ErrorType]()
			
			let types = [HKQuantityTypeIdentifierStepCount, HKQuantityTypeIdentifierFlightsClimbed, HKQuantityTypeIdentifierActiveEnergyBurned]
			for type in types {
				dispatch_group_enter(queueGroup)
				healthStore.c3_summaryOfSamplesOfTypeBetween(type, start: start, end: until) { result, error in
					if let result = result {
						quantities.append(result)
					}
					else if let error = error {
						errors.append(error)
					}
					dispatch_group_leave(queueGroup)
				}
			}
			
			// on group notify, call the callback on the main queue
			dispatch_group_notify(queueGroup, dispatch_get_main_queue()) {
				callback(samples: quantities, error: (errors.count > 0) ? C3Error.MultipleErrors(errors) : nil)
			}
		}
		else {
			c3_logIfDebug("HKHealthStorage is not available")
			callback(samples: nil, error: C3Error.HealthKitNotAvailable)
		}
	}
}

