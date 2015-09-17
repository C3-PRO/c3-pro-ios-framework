//
//  RSAUtility.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/18/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation

let CHIPRSAErrorKey = "CHIPRSAError"


/**
    RSA Encryption helper.
 */
public class RSAUtility
{
	/// The name of the bundled X509 public key certificate (without the .crt part).
	public let publicCertificateFile: String
	
	var publicKey: SecKey?
	
	public init(publicCertificateFile certificateFile: String) {
		publicCertificateFile = certificateFile
	}
	
	
	// MARK: - Encryption
	
	public func encrypt(data: NSData) throws -> NSData {
		if nil == publicKey {
			try readBundledCertificate()
		}
		return try encryptDataWithKey(data, key: publicKey!)
	}
	
	public func encryptDataWithKey(data: NSData, key: SecKey) throws -> NSData {
		let cipherBufferSize = SecKeyGetBlockSize(key)
		let cipherBuffer = NSMutableData(length: Int(cipherBufferSize))
		let cipherBufferPointer = UnsafeMutablePointer<UInt8>(cipherBuffer!.mutableBytes)
		var cipherBufferSizeResult = Int(cipherBufferSize)
		
		let status = SecKeyEncrypt(key,
			SecPadding.OAEP,				// `SecPadding.OAEP` works with RSA/ECB/OAEPWithSHA1AndMGF1Padding on the Java side
			UnsafePointer<UInt8>(data.bytes),
			data.length,
			cipherBufferPointer,
			&cipherBufferSizeResult
		)
		if noErr == status {
			return NSData(bytes:cipherBuffer!.bytes, length:Int(cipherBufferSizeResult))
		}
		throw chip_genErrorRSA("Failed to encrypt data with key: OSStatus \(status)")
	}
	
	
	// MARK: - Certificate Handling
	
	/**
	Tries to read data from `publicCertificateFile`, then forwards to `loadPublicKey()` to instantiate a SecKey.
	*/
	func readBundledCertificate() throws -> SecKey {
		if let keyURL = NSBundle.mainBundle().URLForResource(publicCertificateFile, withExtension: "crt") {
			if let certData = NSData(contentsOfURL: keyURL) {
				let key = try loadPublicKey(certData)
				publicKey = key
				return key
			}
			throw chip_genErrorRSA("Failed to read bundled X509 certificate «\(publicCertificateFile).crt»")
		}
		throw chip_genErrorRSA("Bundled X509 certificate «\(publicCertificateFile).crt» not found")
	}
	
	/**
	Use given data, representing an X509 certificate, to instantiate a SecKey.
	*/
	func loadPublicKey(data: NSData) throws -> SecKey {
		if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data) {
			var trust: SecTrust?
			let policy = SecPolicyCreateBasicX509()
			let status = SecTrustCreateWithCertificates(cert, policy, &trust)
			
			if errSecSuccess == status, let trust = trust {
				if let key = SecTrustCopyPublicKey(trust) {
					return key
				}
				throw chip_genErrorRSA("Failed to copy public key from SecTrust")
			}
			throw chip_genErrorRSA("Failed to create a trust management object from X509 certificate: OSError \(status)")
		}
		throw chip_genErrorRSA("Failed to create SecCertificate from given data")
	}
}


/**
    Convenience function to create an NSError in our questionnaire error domain.
 */
public func chip_genErrorRSA(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPRSAErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

