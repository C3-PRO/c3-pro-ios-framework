//
//  RSAUtility.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/18/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation


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
		throw C3Error.EncryptionFailedWithStatus(status)
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
			throw C3Error.EncryptionX509CertificateNotRead(publicCertificateFile)
		}
		throw C3Error.EncryptionX509CertificateNotFound(publicCertificateFile)
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
				throw C3Error.EncryptionX509CertificateNotLoaded("Failed to copy public key from SecTrust")
			}
			throw C3Error.EncryptionX509CertificateNotLoaded("Failed to create a trust management object from X509 certificate: OSError \(status)")
		}
		throw C3Error.EncryptionX509CertificateNotLoaded("Failed to create SecCertificate from given data")
	}
}

