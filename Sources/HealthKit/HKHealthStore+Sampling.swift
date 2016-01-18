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


public extension HKHealthStore {
	
	/**
	Convenience method to retrieve the latest sample of a given type.
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter callback: Callback to call when query finishes, comes back either with a quantity, an error or neither
	*/
	public func chip_latestSampleOfType(typeIdentifier: String, callback: ((quantity: HKQuantity?, error: ErrorType?) -> Void)) {
		chip_samplesOfTypeBetween(typeIdentifier, start: NSDate.distantPast() , end: NSDate(), limit: 1) { results, error in
			callback(quantity: results?.first?.quantity, error: error)
		}
	}
	
	/**
	Convenience method to retrieve samples from a given period. Orders by end date, descending. Don't use this to get a total over a given
	period, use `chip_summaryOfSamplesOfTypeBetween()` (which is using `HKStatisticsCollectionQuery`).
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter limit: How many samples to retrieve at max
	- parameter callback: Callback to call when query finishes, comes back either with an array of samples, an error or neither
	*/
	public func chip_samplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, limit: Int, callback: ((results: [HKQuantitySample]?, error: ErrorType?) -> Void)) {
		guard let sampleType = HKSampleType.quantityTypeForIdentifier(typeIdentifier) else {
			callback(results: nil, error: C3Error.NoSuchHKSampleType(typeIdentifier))
			return
		}
		
		let period = HKQuery.predicateForSamplesWithStartDate(start, endDate: end, options: .None)
		let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
		let query = HKSampleQuery(sampleType: sampleType, predicate: period, limit: limit, sortDescriptors: [sortDescriptor]) { sampleQuery, results, error in
			if let err = error {
				callback(results: nil, error: err)
			}
			else {
				callback(results: results as? [HKQuantitySample], error: nil)
			}
		}
		executeQuery(query)
	}
	
	/**
	Retrieve a quantity summed over a given period. Uses `HKStatisticsCollectionQuery`, the callback will be called on a background queue.
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter callback: Callback to call, on a background queue, when the query finishes, containing one HKQuantitySample spanning the
	                      whole period or an error (or neither)
	*/
	public func chip_summaryOfSamplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, callback: ((result: HKQuantitySample?, error: ErrorType?) -> Void)) {
		guard let sampleType = HKSampleType.quantityTypeForIdentifier(typeIdentifier) else {
			callback(result: nil, error: C3Error.NoSuchHKSampleType(typeIdentifier))
			return
		}
		
		// we create one interval for the whole period between start and end dates
		let interval = NSCalendar.currentCalendar().components([.Day, .Hour], fromDate: start, toDate: end, options: [])
		guard interval.day + interval.hour > 0 else {
			callback(result: nil, error: C3Error.IntervalTooSmall)
			return
		}
		let period = HKQuery.predicateForSamplesWithStartDate(start, endDate: end, options: .None)
		
		let query = HKStatisticsCollectionQuery(quantityType: sampleType, quantitySamplePredicate: period, options: [.CumulativeSum], anchorDate: start, intervalComponents: interval)
		query.initialResultsHandler = { sampleQuery, results, error in
			if let error = error {
				callback(result: nil, error: error)
			}
			else {
				var sample: HKQuantitySample?
				if let results = results {
					results.enumerateStatisticsFromDate(start, toDate: end) { statistics, stop in
						if let sum = statistics.sumQuantity() {
							sample = HKQuantitySample(type: sampleType, quantity: sum, startDate: start, endDate: end)
							stop.memory = true		// we only expect one summary
						}
					}
				}
				callback(result: sample, error: nil)
			}
		}
		executeQuery(query)
	}
}

