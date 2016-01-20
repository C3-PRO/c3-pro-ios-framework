//
//  AESUtility.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/18/15.
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
import CryptoSwift


/**
Utility to work with symmetric AES encryption. Relies on `CryptoSwift`.
*/
public class AESUtility {
	
	/// Bytes of the key to use, 32 by default.
	public var keySize = 32
	
	/// NSData representation of the symmetric key.
	public var symmetricKeyData: NSData {
		return NSData.withBytes(symmetricKey)
	}
	
	var symmetricKey: [UInt8]
	
	/** Designated initializer. Creates a random symmetric key. */
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
	
	- parameter data: The data to encrypt using the receiver's symmetric key
	- returns: Encryped data representation
	*/
	public func encrypt(data: NSData) throws -> NSData {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		let enc = try aes.encrypt(data.arrayOfBytes())
		return NSData.withBytes(enc)
	}
	
	
	// MARK: - Decryption
	
	/**
	Decrypt given data with the current symmetricKey and an IV parameter of all-zeroes.
	
	- parameter encData: Encrypted data to decrypt using the receiver's symmetric key
	- returns: Decrypted data
	*/
	public func decrypt(encData: NSData) throws -> NSData {
		let aes = AES(key: symmetricKey)!		// this only fails if keySize is wrong
		let dec = try aes.decrypt(encData.arrayOfBytes())
		return NSData.withBytes(dec)
	}
}

