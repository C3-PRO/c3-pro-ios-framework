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
	Convenience method to retrieve samples from a given period. Orders by end date, descending.
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter limit: How many samples to retrieve at max
	- parameter callback: Callback to call when query finishes
	*/
	public func chip_samplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, limit: Int, callback: ((results: [HKQuantitySample]?, error: ErrorType?) -> Void)) {
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
			callback(results: nil, error: C3Error.NoSuchHKSampleType(typeIdentifier))
		}
	}
	
	/**
	Retrieve a summed quantity of a given period. Uses `HKStatisticsCollectionQuery`, the callback will be called on a background queue.
	
	- parameter typeIdentifier: The type of samples to retrieve
	- parameter start: Start date
	- parameter end: End date
	- parameter callback: Callback to call, on a background queueu, when query finishes, containing one HKQuantitySample spanning the whole
	                      period or an error
	*/
	public func chip_summaryOfSamplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, callback: ((result: HKQuantitySample?, error: ErrorType?) -> Void)) {
		if let sampleType = HKSampleType.quantityTypeForIdentifier(typeIdentifier) {
			let period = HKQuery.predicateForSamplesWithStartDate(start, endDate: end, options: .None)
			let interval = NSCalendar.currentCalendar().components([.Day], fromDate: start, toDate: end, options: [])
			
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
								stop.memory = true
							}
						}
					}
					callback(result: sample, error: nil)
				}
			}
			executeQuery(query)
		}
		else {
			callback(result: nil, error: C3Error.NoSuchHKSampleType(typeIdentifier))
		}
	}
}


public extension HKQuantitySample
{
	/**
	Takes an array of quantity samples in the assumption that all samples are of the same type and returns one concatenated
	`HKQuantitySample` object.
	
	TODO: would be cool as a failable initializer, but can't bail out without initializing all ivars first :P
	
	- parameter samples: An array of `HKQuantitySample` instances of the same type
	- parameter unit: The unit to use in the resulting master quantity sample
	- returns: An HKQuantitySample instance concatenating all given sample data
	*/
	public class func chip_concatenatedQuantitySamples(samples: [HKQuantitySample], unit: HKUnit) -> HKQuantitySample? {
		var type: HKQuantityType?
		var dateMin: NSDate?
		var dateMax: NSDate?
		var total = 0.0
		
		for sample in samples {
			let quantity = sample.quantity
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
		
		if let type = type {
			let quantity = HKQuantity(unit: unit, doubleValue: total)
			return HKQuantitySample(type: type, quantity: quantity, startDate: dateMin!, endDate: dateMax!)
		}
		return nil
	}
	
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
			return Quantity(json: ["value": doubleValueForUnit(unit), "units": unit.unitString])
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

