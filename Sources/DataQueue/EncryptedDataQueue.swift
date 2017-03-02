//
//  EncryptedDataQueue.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 8/21/15.
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
import SMART


/**
Protocol for delegates to the encrypted data queue.
*/
public protocol EncryptedDataQueueDelegate {
	
	/** Method called to determine whether the respective resource should be encrypted. */
	func encryptedDataQueue(_ queue: EncryptedDataQueue, wantsEncryptionForResource resource: Resource, requestMethod: FHIRRequestMethod) -> Bool
	
	/** Method that asks for the identifier of the key that should be used for encryption. */
	func keyIdentifierForEncryptedDataQueue(_ queue: EncryptedDataQueue) -> String?
}


/**
Data Queue that can encrypt resources before sending.

This class is a subclass of `DataQueue`, an implementation of a `FHIRServer`.
*/
open class EncryptedDataQueue: DataQueue {
	
	/// An optional delegate to ask when to encrypt a resource and when not; if not provided, all resources will be encrypted.
	open var delegate: EncryptedDataQueueDelegate?
	
	/// The endpoint for encrypted resources; usually different from `baseURL` since these are not FHIR compliant.
	open internal(set) var encryptedBaseURL: URL
	
	let aes = AESUtility()
	
	let rsa: RSAUtility
	
	/**
	Designated initializer.
	
	- parameter baseURL: Base URL for the server's FHIR endpoint
	- parameter auth: OAuth2 settings
	- parameter encBaseURL: The base URL for encrypted resources
	- parameter publicCertificateFile: Filename, without ".crt" extension, of a bundled X509 public key certificate
	*/
	public init(baseURL: URL, auth: OAuth2JSON?, encBaseURL: URL, publicCertificateFile: String) {
		if let lastChar = encBaseURL.absoluteString.characters.last, "/" != lastChar {
			encryptedBaseURL = encBaseURL.appendingPathComponent("/")
		}
		else {
			encryptedBaseURL = encBaseURL
		}
		rsa = RSAUtility(publicCertificateFile: publicCertificateFile)
		super.init(baseURL: baseURL, auth: auth)
	}
	
	/** You CANNOT use this initializer on the encrypted data queue, use `init(baseURL:auth:encBaseURL:publicCertificateFile:)`. */
	public required init(baseURL: URL, auth: OAuth2JSON?) {
	    fatalError("init(baseURL:auth:) cannot be used on `EncryptedDataQueue`, use init(baseURL:auth:encBaseURL:publicCertificateFile:)")
	}
	
	
	// MARK: - Encryption
	
	/**
	Encrypts the given data (which is presumed to be JSON data of a FHIR resource), then creates a JSON representation that also contains
	the encrypted symmetric key and a FHIR version flag and returns data produced when serializing that JSON.
	
	- parameter data: The data to encrypt, presumed to be Data of a JSON-serialized FHIR resource
	- returns:        Data representing JSON
	*/
	public func encrypted(data: Data) throws -> Data {
		let encData = try aes.encrypt(data: data)
		let encKey = try rsa.encrypt(data: aes.symmetricKeyData)
		let dict = [
			"key_id": delegate?.keyIdentifierForEncryptedDataQueue(self) ?? "",
			"symmetric_key": encKey.base64EncodedString(),
			"message": encData.base64EncodedString(),
			"version": C3PROFHIRVersion,
		]
		return try JSONSerialization.data(withJSONObject: dict, options: [])
	}
	
	
	// MARK: - Requests
	
	override open func handlerForRequest(withMethod method: FHIRRequestMethod, resource: Resource?) -> FHIRRequestHandler? {
		if let resource = resource, nil == delegate || delegate!.encryptedDataQueue(self, wantsEncryptionForResource: resource, requestMethod: method) {
			return EncryptedJSONRequestHandler(method, resource: resource, dataQueue: self)
		}
		return super.handlerForRequest(withMethod: method, resource: resource)
	}
	
	override open func absoluteURL(for path: String, handler: FHIRRequestHandler) -> URL? {
		if handler is EncryptedJSONRequestHandler {
			return URL(string: path, relativeTo: encryptedBaseURL)
		}
		return super.absoluteURL(for: path, handler: handler)
	}
}


/**
A request handler for encrypted JSON data, to be used with `EncryptedDataQueue`.

Its `prepareData()` method asks its dataQueue to encrypt the resource.
*/
open class EncryptedJSONRequestHandler: FHIRJSONRequestHandler {
	
	let dataQueue: EncryptedDataQueue
	
	/**
	Designated initializer.
	
	- parameter type: The type of the request
	- parameter resource: The resource to send with this request
	- parameter dataQueue: The `EncryptedDataQueue` instance that's sending this request
	*/
	public init(_ type: FHIRRequestMethod, resource: Resource?, dataQueue: EncryptedDataQueue) {
		self.dataQueue = dataQueue
		super.init(type, resource: resource)
	}
	
	public required init(_ method: FHIRRequestMethod, resource: Resource?) {
		fatalError("init(_:resource:) cannot be used on an encrypted request handler")
	}
	
	/** This implementation asks `dataQueue` to handle resource encryption by calling its `encryptedData()` method. */
	override open func prepareData() throws {
		data = nil					// to avoid double-encryption
		try super.prepareData()
		if let data = data {
			self.data = try dataQueue.encrypted(data: data)
		}
	}
}

