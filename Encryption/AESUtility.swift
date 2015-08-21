//
//  AESUtility.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/18/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import CryptoSwift

let CHIPAESErrorKey = "CHIPAESError"


/**
    Utility to work with symmetric AES encryption. Relies on `CryptoSwift`.
 */
public class AESUtility
{
	/// Bytes of the key to use, 32 by default
	public var keySize = 32
	
	public var symmetricKeyData: NSData {
		return NSData.withBytes(symmetricKey)
	}
	
	var symmetricKey: [UInt8]
	
	public init() {
		symmetricKey = Cipher.randomIV(keySize)
	}
	
	
	// MARK: - Key
	
	/**
	Generate a new random key of `keySize` length.
	*/
	public func randomizeKey() {
		symmetricKey = Cipher.randomIV(keySize)
	}
	
	
	// MARK: - Encryption
	
	/**
	Encrypt given data with the current symmetricKey and an IV parameter of all-zeroes.
	*/
	public func encrypt(data: NSData, error: NSErrorPointer) -> NSData? {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		if let enc = aes.encrypt(data.arrayOfBytes()) {
			return NSData.withBytes(enc)
		}
		if nil != error {
			error.memory = chip_genErrorAES("Failed to encrypt data")
		}
		return nil
	}
	
	
	// MARK: - Decryption
	
	/**
	Decrypt given data with the current symmetricKey and an IV parameter of all-zeroes.
	*/
	public func decrypt(encData: NSData, error: NSErrorPointer) -> NSData? {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		if let dec = aes.decrypt(encData.arrayOfBytes()) {
			return NSData.withBytes(dec)
		}
		else if nil != error {
			error.memory = chip_genErrorAES("Failed to decrypt data")
		}
		return nil
	}
}


/**
    Convenience function to create an NSError in our questionnaire error domain.
 */
public func chip_genErrorAES(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPAESErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

