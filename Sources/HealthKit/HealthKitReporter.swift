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

See [HealthKit/README.md](https://github.com/C3-PRO/c3-pro-ios-framework/tree/master/Sources/HealthKit#activity-reporter) for detailed instructions.
*/
open class HealthKitReporter: ActivityReporter {
	
	/// The health store used by the instance.
	lazy var healthStore = HKHealthStore()
	
	
	public init() {
	}
	
	
	// MARK: - Convenience Methods
	
	/**
	Creates one `ActivityReportPeriod` instance containing summarized HKQuantitySample over the given period.
	*/
	open func reportForActivityPeriod(startingAt start: Date, until: Date, callback: @escaping ((_ period: ActivityReportPeriod?, _ error: Error?) -> Void)) {
		retrieveHealthKitActivitySummary(startingAt: start, until: until) { samples, error in
			
			// create the period
			let period = Period(json: nil)
			period.start = start.fhir_asDateTime()
			period.end = until.fhir_asDateTime()
			
			// Put all data into one ActivityData instance
			let report = ActivityReportPeriod(period: period)
			report.healthKitSamples = samples
			callback(report, error)
		}
	}
	
	
	// MARK: - HealthKit Access
	
	/**
	Samples activity data in HealthKit (steps, flights climbed and active energy) and returns one HKQuantitySample per type in a callback.
	Uses `c3_summaryOfSamplesOfTypeBetween(type:start:end:)` on the receiver's HKHealthStore instance.
	*/
	open func retrieveHealthKitActivitySummary(startingAt start: Date, until: Date, callback: @escaping ((_ samples: [HKQuantitySample]?, _ error: Error?) -> Void)) {
		if HKHealthStore.isHealthDataAvailable() {
			let queueGroup = DispatchGroup()
			var quantities = [HKQuantitySample]()
			var errors = [Error]()
			
			let types = [HKQuantityTypeIdentifier.stepCount, HKQuantityTypeIdentifier.flightsClimbed, HKQuantityTypeIdentifier.activeEnergyBurned]
			for type in types {
				queueGroup.enter()
				healthStore.c3_summaryOfSamplesOfTypeBetween(type, start: start, end: until) { result, error in
					if let result = result {
						quantities.append(result)
					}
					else if let error = error {
						errors.append(error)
					}
					queueGroup.leave()
				}
			}
			
			// on group notify, call the callback on the main queue
			queueGroup.notify(queue: DispatchQueue.main) {
				callback(quantities, (errors.count > 0) ? C3Error.multipleErrors(errors) : nil)
			}
		}
		else {
			c3_logIfDebug("HKHealthStorage is not available")
			callback(nil, C3Error.healthKitNotAvailable)
		}
	}
}

