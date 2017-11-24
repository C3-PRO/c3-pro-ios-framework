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

Upon initialization, you provide the name of the public key file (minus the .crt part) to the instance. This name is automatically used when
it's time to encrypt to read the key from the main Bundle. If your key is *not* in the main bundle, you can call
`loadBundledCertificate(from: <# Bundle #>)` any time before calling `encrypt(data:)` to make the instance read the key from the given bundle.
*/
open class RSAUtility {
	
	/// The name of the bundled X509 public key certificate (without the .crt part).
	open let publicCertificateFile: String
	
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
	open func encrypt(data: Data) throws -> Data {
		if nil == publicKey {
			try loadBundledCertificate()
		}
		return try encrypt(data: data, with: publicKey!)
	}
	
	/**
	Encrypt given data with the provided public key.
	
	- parameter data: The data to encrypt
	- parameter key: The key to use for encryption
	- returns: Encrypted data
	*/
	open func encrypt(data: Data, with key: SecKey) throws -> Data {
		let cipherBufferSize = SecKeyGetBlockSize(key)
		var cipherBufferPointer = [UInt8](repeating: 0, count: Int(cipherBufferSize))
		var cipherBufferSizeResult = Int(cipherBufferSize)
		let dataPointer = data.withUnsafeBytes {
			[UInt8](UnsafeBufferPointer(start: $0, count: data.count))
		}
		
		let status = SecKeyEncrypt(
			key,
			SecPadding.OAEP,				// `SecPadding.OAEP` works with RSA/ECB/OAEPWithSHA1AndMGF1Padding on the Java side
			dataPointer,
			data.count,
			&cipherBufferPointer,
			&cipherBufferSizeResult
		)
		if errSecSuccess == status {
			return Data(bytes: cipherBufferPointer, count: cipherBufferSizeResult)
		}
		throw C3Error.encryptionFailedWithStatus(status)
	}
	
	
	// MARK: - Certificate Handling
	
	/**
	Tries to read data from `publicCertificateFile`, then forwards to `loadPublicKey()` to instantiate a SecKey.
	
	- parameter bundle: The bundle to read the public key from
	- returns: The `SecKey` read from the bundled certificate
	*/
	func readBundledCertificate(from bundle: Bundle) throws -> SecKey {
		if let keyURL = bundle.url(forResource: publicCertificateFile, withExtension: "crt") {
			if let certData = try? Data(contentsOf: keyURL) {
				return try loadPublicKey(from: certData)
			}
			throw C3Error.encryptionX509CertificateNotRead(publicCertificateFile)
		}
		throw C3Error.encryptionX509CertificateNotFound(publicCertificateFile)
	}
	
	/**
	Tries to read data from `publicCertificateFile` in the given bundle, then forwards to `loadPublicKey()` to assign to `publicKey`.
	
	- parameter bundle: The bundle to read the public key from; defaults to the main bundle
	*/
	public func loadBundledCertificate(from bundle: Bundle = Bundle.main) throws {
		publicKey = try readBundledCertificate(from: bundle)
	}
	
	/**
	Use given data, representing an X509 certificate, to instantiate a SecKey.
	
	- parameter data: Date representing a X509 certificate
	- returns:        The `SecKey` loaded from the given data
	*/
	func loadPublicKey(from data: Data) throws -> SecKey {
		if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data as CFData) {
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

