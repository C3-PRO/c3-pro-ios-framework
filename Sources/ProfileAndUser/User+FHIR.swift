//
//  User+FHIR.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 7/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART
import HealthKit


extension User {
	
	/**
	Returns a tuple containing (patient, observations) derived from the receiver.
	
	Observations contain body height and body weight, if they are set on the receiver.
	*/
	public func c3_asPatientAndObservations() -> (patient: Patient, observations: [Observation]?) {
		let patient = Patient()
		patient.id = userId?.fhir_string
		
		// gender
		switch biologicalSex {
		case .male:
			patient.gender = .male
		case .female:
			patient.gender = .female
		case .other:
			patient.gender = .other
		default:
			break
		}
		
		// birthdate
		if let bday = birthDate {
			patient.birthDate = bday.fhir_asDate()
		}
		
		// observations
		var observations = [Observation]()
		do {
			let subject = try patient.asRelativeReference()    // only fails if there is no id
			if let height = c3_heightAsObservation(for: subject) {
				observations.append(height)
			}
			if let weight = c3_weightAsObservation(for: subject) {
				observations.append(weight)
			}
		}
		catch let error {
			c3_logIfDebug("\(error)")
		}
		
		return (patient: patient, observations: observations)
	}
	
	/**
	Returns the receiver's body height as an Observation with LOINC code 8302-2, nil if there's no height.
	*/
	public func c3_heightAsObservation(for subject: Reference) -> Observation? {
		if let height = bodyheight {
			if let quantity = try? height.c3_asFHIRQuantityInUnit(HKUnit.meterUnit(with: .centi)) {
				let obs = c3_observation(for: quantity, withLOINCCode: "8302-2")
				obs.subject = subject
				
				return obs
			}
		}
		return nil
	}
	
	/**
	Returns the receiver's weight as an Observation with LOINC code 3141-9, nil if there's no weight.
	*/
	public func c3_weightAsObservation(for subject: Reference) -> Observation? {
		if let weight = bodyweight {
			if let quantity = try? weight.c3_asFHIRQuantityInUnit(HKUnit.gramUnit(with: .kilo)) {
				let obs = c3_observation(for: quantity, withLOINCCode: "3141-9")
				obs.subject = subject
				
				return obs
			}
		}
		return nil
	}
	
	func c3_observation(for quantity: Quantity, withLOINCCode loinc: FHIRString) -> Observation {
		let coding = Coding()
		coding.system = FHIRURL("http://loinc.org")
		coding.code = loinc
		let code = CodeableConcept()
		code.coding = [coding]
		let obs = Observation(code: code, status: .final)
		obs.valueQuantity = quantity
		
		return obs
	}
}

