//
//  DeIdentifier.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/20/15.
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

import Foundation
import SMART


/**
	Class to help in de-identifying patient data according to HIPAA's Safe Harbor guidelines.
 */
public class DeIdentifier {
	
	var geocoder: Geocoder?
	
	public init() {  }
	
	
	// MARK: - Patient Details
	
	/**
	Takes the given Patient resource and creates a new instance with only HIPAA compliant de-identified data.
	
	- parameter patient: The Patient resource to de-identify
	- parameter callback: The callback to call when de-identification has completed
	*/
	public func hipaaCompliantPatient(patient inPatient: Patient, callback: ((patient: Patient) -> Void)) {
		geocoder = Geocoder()
		geocoder!.hipaaCompliantCurrentAddress() { address, error in
			self.geocoder = nil
			
			let patient = Patient(json: nil)
			patient.id = inPatient.id
			if let address = address {
				patient.address = [address]
			}
			patient.gender = inPatient.gender
			if let bday = inPatient.birthDate {
				patient.birthDate = self.hipaaCompliantBirthDate(bday)
			}
			callback(patient: patient)
		}
	}
	
	/**
	Returns a Date that is compliant to HIPAA's Safe Harbor guidelines: year only and capped at 90 years of age.
	
	- returns: A compliant Date instance
	*/
	public func hipaaCompliantBirthDate(birthdate: Date) -> Date {
		let current = NSDate().fhir_asDate()
		let year = (current.year - birthdate.year) > 90 ? (current.year - 90) : current.year
		return Date(year: year, month: nil, day: nil)
	}
}

