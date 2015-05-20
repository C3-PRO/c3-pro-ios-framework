//
//  ConsentController.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 5/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
    Controller to capture consent in a FHIR Contract resource.
 */
public class ConsentController
{
	public final var contract: Contract?
	
	public init() {
		
	}
	
	public func signConsentWithPatient(patient: Patient, date: NSDate, validUntil: NSDate? = nil) -> Contract? {
		if let reference = patient.asRelativeReference() {
			let myContract = contract ?? Contract(json: nil)
			
			// applicable period
			let period = Period(json: nil)
			period.start = date.fhir_asDateTime()
			if let until = validUntil {
				period.end = until.fhir_asDateTime()
			}
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
			
			#if DEBUG
			let json = myContract.asJSON()
			let jsdata = NSJSONSerialization.dataWithJSONObject(json, options: nil, error: nil)!
			let jsstr = NSString(data: jsdata, encoding: NSUTF8StringEncoding)
			println("CONTRACT  -->  \(jsstr)")
			#endif
			
			return myContract
		}
		
		chip_logIfDebug("Failed to generate a relative reference for the patient, hence cannot sign this consent. Does the patient have an «id»?")
		return nil
	}
}

