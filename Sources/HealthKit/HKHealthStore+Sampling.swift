//
//  HKExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/9/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
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

import HealthKit
import SMART


/**
Extend `HKHealthStore` with methods that query the store for samples:

- `c3_latestSample(ofType:)`:           retrieve the latest sample of the given type.
- `c3_samplesOfTypeBetween()`:          retrieve all samples of a given type between two dates.
- `c3_summaryOfSamplesOfTypeBetween()`: return a summary of all samples of a given type. Use this to get an **aggregate count** of something
                                        over a given period
*/
public extension HKHealthStore {
	
	/**
	Convenience method to retrieve the latest sample of a given type.
	
	- parameter type:     The type of samples to retrieve
	- parameter callback: Callback to call when query finishes, comes back either with a quantity, an error or neither
	*/
	public func c3_latestSample(ofType type: String, callback: @escaping ((HKQuantity?, Error?) -> Void)) {
		c3_samplesOfTypeBetween(type, start: Date.distantPast , end: Date(), limit: 1) { results, error in
			callback(results?.first?.quantity, error)
		}
	}
	
	/**
	Convenience method to retrieve samples from a given period. Orders by end date, descending. Don't use this to get a total over a given
	period, use `c3_summaryOfSamplesOfTypeBetween()` (which is using `HKStatisticsCollectionQuery`).
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter limit: How many samples to retrieve at max
	- parameter callback: Callback to call when query finishes, comes back either with an array of samples, an error or neither
	*/
	public func c3_samplesOfTypeBetween(_ typeIdentifier: String, start: Date, end: Date, limit: Int, callback: @escaping ((_ results: [HKQuantitySample]?, _ error: Error?) -> Void)) {
		guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeIdentifier)) else {
			callback(nil, C3Error.noSuchHKSampleType(typeIdentifier))
			return
		}
		
		let period = HKQuery.predicateForSamples(withStart: start, end: end, options: HKQueryOptions())
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery(sampleType: sampleType, predicate: period, limit: limit, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error in
			if let err = error {
				callback(nil, err)
			}
			else {
				callback(results as? [HKQuantitySample], nil)
			}
		}
		execute(query)
	}
	
	/**
	Retrieve a quantity summed over a given period. Uses `HKStatisticsCollectionQuery`, the callback will be called on a background queue.
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter callback: Callback to call, on a background queue, when the query finishes, containing one HKQuantitySample spanning the
	                      whole period or an error (or neither)
	*/
	public func c3_summaryOfSamplesOfTypeBetween(_ typeIdentifier: String, start: Date, end: Date, callback: @escaping ((_ result: HKQuantitySample?, _ error: Error?) -> Void)) {
		guard let sampleType = HKSampleType.quantityType(forIdentifier: HKQuantityTypeIdentifier(rawValue: typeIdentifier)) else {
			callback(nil, C3Error.noSuchHKSampleType(typeIdentifier))
			return
		}
		
		// we create one interval for the whole period between start and end dates
		let interval = Calendar.current.dateComponents([.day, .hour], from: start, to: end)
		guard interval.day! + interval.hour! > 0 else {
			callback(nil, C3Error.intervalTooSmall)
			return
		}
		let period = HKQuery.predicateForSamples(withStart: start, end: end, options: HKQueryOptions())
		
		let query = HKStatisticsCollectionQuery(quantityType: sampleType, quantitySamplePredicate: period, options: [.cumulativeSum], anchorDate: start, intervalComponents: interval)
		query.initialResultsHandler = { sampleQuery, results, error in
			if let error = error {
				callback(nil, error)
			}
			else {
				var sample: HKQuantitySample?
				if let results = results {
					results.enumerateStatistics(from: start, to: end) { statistics, stop in
						if let sum = statistics.sumQuantity() {
							sample = HKQuantitySample(type: sampleType, quantity: sum, start: start, end: end)
							stop.pointee = true		// we only expect one summary
						}
					}
				}
				callback(sample, nil)
			}
		}
		execute(query)
	}
}

