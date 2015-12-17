//
//  HKExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/9/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import HealthKit
import SMART


public extension HKQuantitySample {
	
	/**
	Returns a FHIR "Quantity" element of the quantitiy contained in the receiver in the quantity type's preferred unit.
	
	- returns: A Quantity instance on success
	*/
	public func chip_asFHIRQuantity() throws -> Quantity {
		return try quantity.chip_asFHIRQuantityInUnit(quantityType.chip_preferredUnit())
	}
}


public extension HKQuantity {
	
	/**
	Returns a FHIR "Quantity" element with the given unit, **if** the quantity can be represented in that unit.
	
	- parameter unit: The unit to use
	- returns: A Quantity instance on success
	*/
	public func chip_asFHIRQuantityInUnit(unit: HKUnit) throws -> Quantity {
		if isCompatibleWithUnit(unit) {
			return Quantity(json: ["value": doubleValueForUnit(unit), "unit": unit.unitString])
		}
		throw C3Error.QuantityNotCompatibleWithUnit
	}
}


public extension HKQuantityType {
	
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

