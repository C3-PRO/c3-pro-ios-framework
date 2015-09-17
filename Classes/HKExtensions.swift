//
//  HKExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/9/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import HealthKit
import SMART

let CHIPHealthKitErrorKey = "CHIPHealthKitError"


public extension HKHealthStore
{
	/**
	Convenience method to retrieve the latest sample of a given type.
	*/
	public func chip_latestSampleOfType(typeIdentifier: String, callback: ((quantity: HKQuantity?, error: NSError?) -> Void)) {
		chip_samplesOfTypeBetween(typeIdentifier, start: NSDate.distantPast() , end: NSDate(), limit: 1) { results, error in
			callback(quantity: results?.first?.quantity, error: error)
		}
	}
	
	/**
	Convenience method to retrieve samples from a given period.
	
	- parameter typeIdentifier: The sample type to receivec
	- parameter start: Start date
	- parameter end: End date
	- parameter limit: How many samples to retrieve at max
	- parameter callback: Callback to call when query finishes
	*/
	public func chip_samplesOfTypeBetween(typeIdentifier: String, start: NSDate, end: NSDate, limit: Int, callback: ((results: [HKQuantitySample]?, error: NSError?) -> Void)) {
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

