//
//  EncryptionTests.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 18.08.16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import XCTest
@testable import C3PRO
import SMART


class EncryptionTests: XCTestCase {
	
	var aes: AESUtility?
	
	var rsa: RSAUtility?
	
	override func setUp() {
		super.setUp()
		let key = "why-is-this-here".data(using: String.Encoding.utf8)!
//		let key = Data(base64Encoded: "d2h5LWlzLXRoaXMtaGVyZQ==")!		// this is the base64-encoded version
		aes = AESUtility(key: Array(key))
		XCTAssertNotNil(aes)
		
		rsa = RSAUtility(publicCertificateFile: "public")
		XCTAssertNotNil(rsa)
		try? rsa?.loadBundledCertificate(from: Bundle(for: type(of: self)))
	}
	
	func DONTtestRSA() {
		do {
			let quest = try Bundle(for: type(of: self)).fhir_bundledResource("dates", subdirectory: "QuestionnaireResponse", type: QuestionnaireResponse.self)
			
			// encrypt
			let data = try JSONSerialization.data(withJSONObject: quest.asJSON(), options: [])
			let encData = try aes!.encrypt(data: data)
			let encKey = try rsa!.encrypt(data: aes!.symmetricKeyData)
			let dict = [
				"key_id": "public",
				"symmetric_key": encKey.base64EncodedString(),
				"message": encData.base64EncodedString(),
				"version": C3PROFHIRVersion,
			]
			print(dict)
			
			// TODO: implement decryption?
		}
		catch let error {
			XCTAssertNil(error)
		}
	}
	
	func testAESEncryption() {
		do {
			let toEnc = "Let's encrypt!".data(using: String.Encoding.utf8)!
			
			let enc = try aes!.encrypt(data: toEnc)
			let enc64 = enc.base64EncodedString()
			XCTAssertEqual("Iy8Mbj2ye1fI0yUWvyzwWw==", enc64)
		}
		catch let error {
			XCTAssertNil(error)
		}
	}
	
	func testAESDecryption() {
		do {
			let toDec = Data(base64Encoded: "Iy8Mbj2ye1fI0yUWvyzwWw==")!
			
			let dec = try aes!.decrypt(encData: toDec)
			let decStr = String(data: dec, encoding: String.Encoding.utf8)
			XCTAssertEqual("Let's encrypt!", decStr)
		}
		catch let error {
			XCTAssertNil(error)
		}
	}
}

