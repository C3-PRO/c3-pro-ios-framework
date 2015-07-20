//
//  ConsentController.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 5/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


public typealias ConsentSigningCallback = ((contract: Contract, patient: Patient, error: NSError?) -> Void)

let CHIPConsentingErrorKey = "CHIPConsentingError"


/**
    Controller to capture consent in a FHIR Contract resource.
 */
public class ConsentController
{
	/// The contract to be signed; if nil when signing, a new instance will be created.
	public final var contract: Contract?
	
	var deidentifier: DeIdentifier?
	
	public init() {  }
	
	
	// MARK: - Consenting
	
	/**
	Instantiates a new "Contract" resource and fills the properties to represent a consent signed by a participant referencing the given
	patient.
	*/
	public func signContractWithPatient(patient: Patient, date: NSDate, error: NSErrorPointer) -> Contract? {
		if nil == patient.id {
			patient.id = NSUUID().UUIDString
		}
		if let reference = patient.asRelativeReference() {
			let myContract = contract ?? Contract(json: nil)
			
			// applicable period
			let period = Period(json: nil)
			period.start = date.fhir_asDateTime()
			myContract.applies = period
			
			// the participant/patient is the signer
			let signer = ContractSigner(json: nil)
			signer.type = Coding(json: nil)
			signer.type!.display = "Consent"
			signer.type!.code = "1.2.840.10065.1.12.1.7"
			signer.type!.system = NSURL(string: "http://hl7.org/fhir/vs/contract-signer-type")
			signer.party = reference
			signer.signature = patient.id
			myContract.signer = [signer]
			
			return myContract
		}
		
		if nil != error {
			error.memory = chip_genErrorConsenting("Failed to generate a relative reference for the patient, hence cannot sign this consent")
		}
		chip_logIfDebug("Failed to generate a relative reference for the patient, hence cannot sign this consent")
		return nil
	}
	
	/**
	Reverse geocodes and de-identifies the patient, then uses the new Patient resource to sign the contract.
	*/
	public func deIdentifyAndSignConsentWithPatient(patient: Patient, date: NSDate, callback: ConsentSigningCallback) {
		deidentifier = DeIdentifier()
		deidentifier!.hipaaCompliantPatient(patient: patient) { patient in
			self.deidentifier = nil
			
			var error: NSError?
			if let contract = self.signContractWithPatient(patient, date: date, error: &error) {
				callback(contract: contract, patient: patient, error: nil)
			}
			else {
				callback(contract: Contract(json: nil), patient: patient, error: error)
			}
		}
	}
}


/**
	Convenience function to create an NSError in the Consenting error domain.
 */
public func chip_genErrorConsenting(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPConsentingErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

