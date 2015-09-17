//
//  AESUtility.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/18/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import CryptoSwift


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
	public func encrypt(data: NSData) throws -> NSData {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		let enc = try aes.encrypt(data.arrayOfBytes())
		return NSData.withBytes(enc)
	}
	
	
	// MARK: - Decryption
	
	/**
	Decrypt given data with the current symmetricKey and an IV parameter of all-zeroes.
	*/
	public func decrypt(encData: NSData) throws -> NSData {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		let dec = try aes.decrypt(encData.arrayOfBytes())
		return NSData.withBytes(dec)
	}
}

