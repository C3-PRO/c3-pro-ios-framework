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
Extending `HKQuantitySample` to enable easy conversion into a FHIR `Quantity` resource.
*/
public extension HKQuantitySample {
	
	/**
	Returns a FHIR "Quantity" element of the quantitiy contained in the receiver in the quantity type's preferred unit.
	
	- returns: A Quantity instance on success
	*/
	public func c3_asFHIRQuantity() throws -> Quantity {
		return try quantity.c3_asFHIRQuantityInUnit(quantityType.c3_preferredUnit())
	}
}


/**
Extending `HKQuantity` to enable easy conversion into a FHIR `Quantity` resource.
*/
public extension HKQuantity {
	
	/**
	Returns a FHIR "Quantity" element with the given unit, **if** the quantity can be represented in that unit.
	
	- parameter unit: The unit to use
	- returns: A Quantity instance on success
	*/
	public func c3_asFHIRQuantityInUnit(_ unit: HKUnit) throws -> Quantity {
		if `is`(compatibleWith: unit) {
			let quantity = Quantity()
			quantity.value = FHIRDecimal("\(doubleValue(for: unit))")
			quantity.unit = FHIRString(unit.unitString)
			return quantity
		}
		throw C3Error.quantityNotCompatibleWithUnit
	}
}


/**
Extending `HKQuantityType` with a method to return the preferred unit of the quantity type.
*/
public extension HKQuantityType {
	
	/**
	The preferred unit for a given quantity type; should be highly aligned with the ISO units.
	*/
	public func c3_preferredUnit() -> HKUnit {
		switch identifier {
		case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
			return HKUnit.jouleUnit(with: .kilo)
		case HKQuantityTypeIdentifier.bodyMass.rawValue:
			return HKUnit.gramUnit(with: .kilo)
		case HKQuantityTypeIdentifier.bodyTemperature.rawValue:
			return HKUnit.degreeCelsius()
		case HKQuantityTypeIdentifier.height.rawValue:
			return HKUnit.meter()
		case HKQuantityTypeIdentifier.flightsClimbed.rawValue:
			return HKUnit.count()
		case HKQuantityTypeIdentifier.stepCount.rawValue:
			return HKUnit.count()
		// TODO: add more
		default:
			return HKUnit.gram()
		}
	}
}

