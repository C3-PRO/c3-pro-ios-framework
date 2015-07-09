//
//  HKExtensions.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 7/9/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import HealthKit

let CHIPHealthKitErrorKey = "CHIPHealthKitError"


public extension HKHealthStore
{
	/**
	Convenience method to retrieve the latest sample of a given type.
	*/
	public func latestSampleOfType(typeIdentifier: String, callback: ((quantity: HKQuantity?, error: NSError?) -> Void)) {
		samplesOfTypeBetween(typeIdentifier, start: NSDate.distantPast() as! NSDate, end: NSDate(), limit: 1) { results, error in
			callback(quantity: results?.first?.quantity, error: error)
		}
	}
	
	/**
	Convenience method to retrieve samples from a given period.
	
	:param typeIdentifier: The sample type to receivec
	:param start: Start date
	:param end: End date
	:param limit: How many samples to retrieve at max
	:param callback: Callback to call when query finishes
	*/
	public func samplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, limit: Int, callback: ((results: [HKQuantitySample]?, error: NSError?) -> Void)) {
		if let sampleType = HKSampleType.quantityTypeForIdentifier(typeIdentifier) {
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
		else {
			let error = NSError(domain: CHIPHealthKitErrorKey, code: 1, userInfo: [NSLocalizedDescriptionKey: "There is no such HKSampleType: \(typeIdentifier)"])
			callback(results: nil, error: error)
		}
	}
}


public extension HKQuantitySample
{
	/**
	Takes an array of quantity samples in the assumption that all samples are of the same type and returns one concatenated
	`HKQuantitySample` object.
	
	TODO: would be cool as a failable initializer, but can't bail out without initializing all ivars first :P
	
	:param samples: An array of `HKQuantitySample` instances of the same type
	:param unit: The unit to use in the resulting master quantity sample
	:returns: An HKQuantitySample instance concatenating all given sample data
	*/
	public class func concatenatedQuantitySample(samples: [HKQuantitySample], unit: HKUnit) -> HKQuantitySample? {
		var type: HKQuantityType?
		var dateMin: NSDate?
		var dateMax: NSDate?
		var total = 0.0
		
		for sample in samples {
			if let quantity = sample.quantity {
				if nil == type {
					type = sample.quantityType
				}
				dateMin = (nil != dateMin) ? dateMin?.earlierDate(sample.startDate) : sample.startDate
				dateMax = (nil != dateMax) ? dateMax?.laterDate(sample.endDate) : sample.endDate
				if !quantity.isCompatibleWithUnit(unit) {
					chip_warn("sample \(sample) is not compatible with unit \(unit), not adding to quantity")
				}
				else {
					total += quantity.doubleValueForUnit(unit)
				}
			}
		}
		
		if let type = type {
			let quantity = HKQuantity(unit: unit, doubleValue: total)
			return HKQuantitySample(type: type, quantity: quantity, startDate: dateMin!, endDate: dateMax!)
		}
		return nil
	}
}

