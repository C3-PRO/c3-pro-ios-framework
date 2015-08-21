//
//  EncryptedDataQueue.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/21/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART


public protocol EncryptedDataQueueDelegate
{
	func encryptedDataQueue(queue: EncryptedDataQueue, wantsEncryptionForResource resource: FHIRResource, requestType: FHIRRequestType) -> Bool
	
	func keyIdentifierForEncryptedDataQueue(queue: EncryptedDataQueue) -> String?
}


/**
    Data Queue that can encrypt resources before sending.
 */
public class EncryptedDataQueue: DataQueue
{
	/// An optional delegate to ask when to encrypt a resource and when not; if not provided, all resources will be encrypted.
	public var delegate: EncryptedDataQueueDelegate?
	
	/// The endpoint for encrypted resources; usually different from `baseURL` since these are not FHIR compliant.
	public internal(set) var encryptedBaseURL: NSURL
	
	let aes = AESUtility()
	
	let rsa: RSAUtility
	
	/**
	Designated initializer.
	
	:param baseURL: Base URL for the server's FHIR endpoint
	:param auth: OAuth2 settings
	:param encBaseURL: The base URL for encrypted resources
	:param publicCertificateFile: Filename, without ".crt" extension, of a bundled X509 public key certificate
	*/
	public init(baseURL: NSURL, auth: OAuth2JSON?, encBaseURL: NSURL, publicCertificateFile: String) {
		if let baseStr = encBaseURL.absoluteString where baseStr[advance(baseStr.endIndex, -1)] != "/" {
			encryptedBaseURL = encBaseURL.URLByAppendingPathComponent("/")
		}
		else {
			encryptedBaseURL = encBaseURL
		}
		rsa = RSAUtility(publicCertificateFile: publicCertificateFile)
		super.init(baseURL: baseURL, auth: auth)
	}
	
	
	// MARK: - Encryption
	
	public func encryptedData(data: NSData, error: NSErrorPointer) -> NSData? {
		if let encData = aes.encrypt(data, error: error) {
			if let encKey = rsa.encrypt(aes.symmetricKeyData, error: error) {
				let dict = [
					"key_id": delegate?.keyIdentifierForEncryptedDataQueue(self) ?? "",
					"symmetric_key": encKey.base64EncodedStringWithOptions(nil),
					"message": encData.base64EncodedStringWithOptions(nil),
				]
				return NSJSONSerialization.dataWithJSONObject(dict, options: nil, error: error)
			}
		}
		return nil
	}
	
	
	// MARK: - Requests
	
	public override func handlerForRequestOfType(type: FHIRRequestType, resource: FHIRResource?) -> FHIRServerRequestHandler? {
		if let resource = resource where nil == delegate || delegate!.encryptedDataQueue(self, wantsEncryptionForResource: resource, requestType: type) {
			return EncryptedJSONRequestHandler(type, resource: resource, dataQueue: self)
		}
		return super.handlerForRequestOfType(type, resource: resource)
	}
	
	public override func absoluteURLForPath(path: String, handler: FHIRServerRequestHandler) -> NSURL? {
		if handler is EncryptedJSONRequestHandler {
			return NSURL(string: path, relativeToURL: encryptedBaseURL)
		}
		return super.absoluteURLForPath(path, handler: handler)
	}
}


public class EncryptedJSONRequestHandler: FHIRServerJSONRequestHandler
{
	let dataQueue: EncryptedDataQueue
	
	init(_ type: FHIRRequestType, resource: FHIRResource?, dataQueue: EncryptedDataQueue) {
		self.dataQueue = dataQueue
		super.init(type, resource: resource)
	}
	
	public override func prepareData(error: NSErrorPointer) -> Bool {
		if super.prepareData(error) {
			if let data = data {
				if let encrypted = dataQueue.encryptedData(data, error: error) {
					self.data = encrypted
					return true
				}
				return false
			}
			return true			// e.g. GET requests that do not have data to prepare
		}
		return false
	}
}

