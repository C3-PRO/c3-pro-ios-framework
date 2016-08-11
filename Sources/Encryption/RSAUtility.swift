//
//  RSAUtility.swift
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


/**
RSA Encryption helper.
*/
public class RSAUtility {
	
	/// The name of the bundled X509 public key certificate (without the .crt part).
	public let publicCertificateFile: String
	
	var publicKey: SecKey?
	
	/**
	Designated initializer.
	
	- parameter publicCertificateFile: Name of the bundled X509 public key certificate (without the .crt extension)
	*/
	public init(publicCertificateFile certificateFile: String) {
		publicCertificateFile = certificateFile
	}
	
	
	// MARK: - Encryption
	
	/**
	Encrypt given data using the receiver's public key.
	
	- parameter data: The data to encrypt
	- returns: Encrypted data
	*/
	public func encrypt(data: Data) throws -> Data {
		if nil == publicKey {
			publicKey = try readBundledCertificate()
		}
		return try encryptDataWithKey(data, key: publicKey!)
	}
	
	/**
	Encrypt given data with the provided public key.
	
	- parameter data: The data to encrypt
	- parameter key: The key to use for encryption
	- returns: Encrypted data
	*/
	public func encryptDataWithKey(_ data: Data, key: SecKey) throws -> Data {
		let cipherBufferSize = SecKeyGetBlockSize(key)
		let cipherBuffer = NSMutableData(length: Int(cipherBufferSize))
		let cipherBufferPointer = UnsafeMutablePointer<UInt8>(cipherBuffer!.mutableBytes)
		var cipherBufferSizeResult = Int(cipherBufferSize)
		
		let status = SecKeyEncrypt(key,
			SecPadding.OAEP,				// `SecPadding.OAEP` works with RSA/ECB/OAEPWithSHA1AndMGF1Padding on the Java side
			UnsafePointer<UInt8>((data as NSData).bytes),
			data.count,
			cipherBufferPointer,
			&cipherBufferSizeResult
		)
		if noErr == status {
			return Data(bytes: UnsafePointer<UInt8>(cipherBuffer!.bytes), count:Int(cipherBufferSizeResult))
		}
		throw C3Error.encryptionFailedWithStatus(status)
	}
	
	
	// MARK: - Certificate Handling
	
	/**
	Tries to read data from `publicCertificateFile`, then forwards to `loadPublicKey()` to instantiate a SecKey.
	
	- returns: The `SecKey` read from the bundled certificate
	*/
	func readBundledCertificate() throws -> SecKey {
		if let keyURL = Bundle.main.url(forResource: publicCertificateFile, withExtension: "crt") {
			if let certData = try? Data(contentsOf: keyURL) {
				return try loadPublicKey(certData)
			}
			throw C3Error.encryptionX509CertificateNotRead(publicCertificateFile)
		}
		throw C3Error.encryptionX509CertificateNotFound(publicCertificateFile)
	}
	
	/**
	Use given data, representing an X509 certificate, to instantiate a SecKey.
	
	- parameter data: Date representing a X509 certificate
	- returns: The `SecKey` loaded from the given data
	*/
	func loadPublicKey(_ data: Data) throws -> SecKey {
		if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data) {
			var trust: SecTrust?
			let policy = SecPolicyCreateBasicX509()
			let status = SecTrustCreateWithCertificates(cert, policy, &trust)
			
			if errSecSuccess == status, let trust = trust {
				if let key = SecTrustCopyPublicKey(trust) {
					return key
				}
				throw C3Error.encryptionX509CertificateNotLoaded("Failed to copy public key from SecTrust")
			}
			throw C3Error.encryptionX509CertificateNotLoaded("Failed to create a trust management object from X509 certificate: OSError \(status)")
		}
		throw C3Error.encryptionX509CertificateNotLoaded("Failed to create SecCertificate from given data")
	}
}

