//
//  HKExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/9/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import HealthKit
import SMART


public extension HKHealthStore {
	/**
	Convenience method to retrieve the latest sample of a given type.
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
	- parameter callback: Callback to call when query finishes
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
	                      whole period or an error
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


public extension HKQuantitySample {
	
	/**
	Returns a FHIR "Quantity" element of the quantitiy contained in the receiver in the quantity type's preferred unit.
	
	- returns: A Quantity instance on success
	*/
	public func chip_asFHIRQuantity() -> Quantity? {
		return quantity.chip_asFHIRQuantityInUnit(quantityType.chip_preferredUnit())
	}
}


public extension HKQuantity
{
	/**
	Returns a FHIR "Quantity" element with the given unit, **if** the quantity can be represented in that unit.
	
	- parameter unit: The unit to use
	- returns: A Quantity instance on success
	*/
	public func chip_asFHIRQuantityInUnit(unit: HKUnit) -> Quantity? {
		if isCompatibleWithUnit(unit) {
			return Quantity(json: ["value": doubleValueForUnit(unit), "unit": unit.unitString])
		}
		chip_warn("not compatible with unit \(unit): \(self)")
		return nil
	}
}


public extension HKQuantityType
{
	/**
	The preferred unit for a given quantity type; should be highly aligned with the ISO units.
	*/
	public func chip_preferredUnit() -> HKUnit {
		switch identifier {
		case HKQuantityTypeIdentifierActiveEnergyBurned:
			return HKUnit.jouleUnitWithMetricPrefix(.Kilo)
		case HKQuantityTypeIdentifierBodyMass:
			return HKUnit.gramUnitWithMetricPrefix(.Kilo)
		case HKQuantityTypeIdentifierBodyTemperature:
			return HKUnit.degreeCelsiusUnit()
		case HKQuantityTypeIdentifierHeight:
			return HKUnit.meterUnit()
		case HKQuantityTypeIdentifierFlightsClimbed:
			return HKUnit.countUnit()
		case HKQuantityTypeIdentifierStepCount:
			return HKUnit.countUnit()
		// TODO: add more
		default:
			return HKUnit.gramUnit()
		}
	}
}

