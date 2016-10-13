//
//  ConsentControllerTests.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 17.08.16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import XCTest
@testable import C3PRO
import SMART


class ConsentControllerTests: XCTestCase {
	
	func testSigning() {
		do {
			let bundle = Bundle(for: type(of: self))
			let controller = try ConsentController()
			controller.contract = try bundle.fhir_bundledResource("sample-consent", subdirectory: "Contract", type: Contract.self)
			XCTAssertNotNil(controller.contract, "Must parse contract")
			
			let patient = Patient(json: ["resourceType": "Patient", "id": "RK201608XDH", "name": [["given": ["Jack"], "family": ["Rabbit"]]]])
			let result = ConsentResult(signature: nil)
			result.consentDate = Instant(string: "2016-08-17T09:54:40Z")?.nsDate
			result.participantGivenName = "Jack"
			result.participantFamilyName = "Rabbit"
			result.shareWidely = true
			
			let signed = try controller.signContract(with: patient, result: result)
			XCTAssertNotNil(signed.signer)
			XCTAssertEqual(1, signed.signer?.count)
			
			// is the data sharing extension present?
			XCTAssertNotNil(signed.signer?[0].extension_fhir)
			XCTAssertEqual(1, signed.signer?[0].extension_fhir?.count)
			XCTAssertEqual("http://fhir-registry.smarthealthit.org/StructureDefinition/consents-to-data-sharing", signed.signer?[0].extension_fhir?[0].url?.description)
			XCTAssertEqual(true, signed.signer?[0].extension_fhir?[0].valueBoolean)
			
			// correct signature type?
			XCTAssertNotNil(signed.signer?[0].signature)
//			XCTAssertEqual(1, signed.signer?[0].signature?.count)
//			XCTAssertNotNil(signed.signer?[0].signature?[0].type)
//			XCTAssertEqual(1, signed.signer?[0].signature?[0].type?.count)
//			XCTAssertEqual("http://hl7.org/fhir/ValueSet/signature-type", signed.signer?[0].signature?[0].type?[0].system?.description)
//			XCTAssertEqual("1.2.840.10065.1.12.1.7", signed.signer?[0].signature?[0].type?[0].code)
			
			/*/ simpy compare to serialized version for a full validation
			let serialized = try JSONSerialization.data(withJSONObject: signed.asJSON(), options: [])
			let reference = try bundle.fhir_bundledResource("sample-consent-signed", subdirectory: "Contract", type: Contract.self)
			reference.id = "sample-consent"
			let serializedReference = try JSONSerialization.data(withJSONObject: reference.asJSON(), options: [])
			XCTAssertEqual(String(data: serialized, encoding: String.Encoding.utf8)!, String(data: serializedReference, encoding: String.Encoding.utf8)!)
			
			// if NOT asking to share, make sure the extension is NOT present
			result.shareWidely = nil
			
			let signed2 = try controller.signContract(with: patient, result: result)
			XCTAssertNotNil(signed2.signer)
			XCTAssertEqual(1, signed2.signer?.count)
			XCTAssertNil(signed2.signer?[0].extension_fhir)	//	*/
		}
		catch let error {
			XCTAssertNil(error)
		}
	}
}

