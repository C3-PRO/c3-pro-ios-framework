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
	
	public func encrypt(data: NSData, error: NSErrorPointer) -> NSData? {
		if let key = publicKey ?? readBundledCertificate(error) {
			return encryptDataWithKey(data, key: key, error: error)
		}
		return nil
	}
	
	public func encryptDataWithKey(data: NSData, key: SecKey, error: NSErrorPointer) -> NSData? {
		let cipherBufferSize = SecKeyGetBlockSize(key)
		let cipherBuffer = NSMutableData(length: Int(cipherBufferSize))
		let cipherBufferPointer = UnsafeMutablePointer<UInt8>(cipherBuffer!.mutableBytes)
		var cipherBufferSizeResult = Int(cipherBufferSize)
		
		let status = SecKeyEncrypt(key,
			UInt32(kSecPaddingOAEP),				// `kSecPaddingOAEP` works with RSA/ECB/OAEPWithSHA1AndMGF1Padding on the Java side
			UnsafePointer<UInt8>(data.bytes),
			data.length,
			cipherBufferPointer,
			&cipherBufferSizeResult
		)
		if status == noErr {
			return NSData(bytes:cipherBuffer!.bytes, length:Int(cipherBufferSizeResult))
		}
		if nil != error {
			error.memory = chip_genErrorRSA("Failed to encrypt data with key: OSStatus \(status)")
		}
		return nil
	}
	
	
	// MARK: - Certificate Handling
	
	func readBundledCertificate(error: NSErrorPointer) -> SecKey? {
		if let keyURL = NSBundle.mainBundle().URLForResource(publicCertificateFile, withExtension: "crt") {
			if let certData = NSData(contentsOfURL: keyURL) {
				if let key = loadPublicKey(certData, error: error) {
					publicKey = key
					return key
				}
			}
			else if nil != error {
				error.memory = chip_genErrorRSA("Failed to read bundled X509 certificate «\(publicCertificateFile).crt»")
			}
		}
		else if nil != error {
			error.memory = chip_genErrorRSA("Bundled X509 certificate «\(publicCertificateFile).crt» not found")
		}
		return nil
	}
	
	func loadPublicKey(data: NSData, error: NSErrorPointer) -> SecKey? {
		if let cert = SecCertificateCreateWithData(kCFAllocatorDefault, data)?.takeRetainedValue() {
			var trust: Unmanaged<SecTrust>?
			let policy = SecPolicyCreateBasicX509().takeRetainedValue()
			let status = SecTrustCreateWithCertificates(cert, policy, &trust)
			
			if status == errSecSuccess {
				let trustRef = trust!.takeRetainedValue()
				let key = SecTrustCopyPublicKey(trustRef)!.takeRetainedValue();
				
				return key
			}
			else if nil != error {
				error.memory = chip_genErrorRSA("Failed to create a trust management object from X509 certificate: OSError \(status)")
			}
		}
		else if nil != error {
			error.memory = chip_genErrorRSA("Failed to create SecCertificate from data")
		}
		return nil
	}
}


/**
    Convenience function to create an NSError in our questionnaire error domain.
 */
public func chip_genErrorRSA(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPRSAErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

