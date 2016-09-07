//
//  OAuth2DynRegAppStore.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 6/2/15.
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

import SMART
import StoreKit


/**
Dynamic client registration based on the app's App Store receipt.
*/
open class OAuth2DynRegAppStore: OAuth2DynReg {
	
	deinit {
		if let delegate = refreshDelegate {
			refreshRequest?.cancel()
			delegate.callback(OAuth2Error.generic("App Store Receipt refresh cancelled [deinit]"))
		}
	}
	
	/// Whether the sandbox environment should be used. You can't set this during build-time since TestFlight is now sending out the same
	/// binary as will end up in the App Store.
	open var sandbox = false
	
	/// The App Receipt, read from file.
	var appReceipt: String?
	
	var refreshRequest: SKReceiptRefreshRequest?
	
	var refreshDelegate: AppStoreRequestDelegate?
	
	override open func register(client: OAuth2, callback: ((OAuth2JSON?, OAuth2Error?) -> Void)) {
		if ensureHasAppReceipt() {
			super.register(client: client, callback: callback)
		}
		else {
			refreshAppReceipt() { error in
				if let error = error {
					if SKErrorDomain == error._domain && SKError.unknown.rawValue == error._code {
						callback(nil, OAuth2Error.generic("\(C3Error.appReceiptRefreshFailed)"))
					}
					else {
						callback(nil, OAuth2Error.generic("\(error)"))
					}
				}
				else {
					super.register(client: client, callback: callback)
				}
			}
		}
	}
	
	override open func registrationBody(for client: OAuth2) -> OAuth2JSON {
		var dict = super.registrationBody(for: client)
		dict["sandbox"] = sandbox
		dict["receipt-data"] = appReceipt
		return dict
	}
	
	
	// MARK: - App Store Receipt
	
	/**
	Reads from `appStoreReceiptURL` if `appReceipt` is nil
	
	- returns: A bool indicating the present of the App Store receipt
	*/
	func ensureHasAppReceipt() -> Bool {
		if nil == appReceipt, let receiptURL = Bundle.main.appStoreReceiptURL {
			if let receipt = try? Data(contentsOf: receiptURL) {
				appReceipt = receipt.base64EncodedString(options: [])
			}
		}
		return (nil != appReceipt)
	}
	
	/**
	Asks the OS to refresh the App Store receipt.
	
	Uses `SKReceiptRefreshRequest` with `AppStoreRequestDelegate`, which the receiver is holding on to.
	
	- parameter callback: The callback to call, containing an optional error when refresh is done
	*/
	func refreshAppReceipt(callback: ((Error?) -> Void)) {
		if let delegate = refreshDelegate {
			refreshRequest?.cancel()
			delegate.callback(OAuth2Error.generic("App Store Receipt refresh timeout"))
		}
		refreshDelegate = AppStoreRequestDelegate(callback: { error in
			callback(error)
			self.refreshRequest = nil
			self.refreshDelegate = nil
		})
		
		let refresh = SKReceiptRefreshRequest(receiptProperties: nil)
		refresh.delegate = refreshDelegate
		refreshRequest = refresh
		refresh.start()
	}
}


/**
Simple object used by `OAuth2DynRegAppStore` to use block-based callbacks on an SKRequest.
*/
class AppStoreRequestDelegate: NSObject, SKRequestDelegate {
	
	/// The callback to call when done or on error.
	let callback: ((Error?) -> Void)
	
	
	/**
	Designated initializer.
	
	- parameter callback: The callback the instance should hold on to
	*/
	init(callback: ((Error?) -> Void)) {
		self.callback = callback
	}
	
	
	// MARK: - Delegate Methods
	
	func requestDidFinish(_ request: SKRequest) {
		callback(nil)
	}
	
	func request(_ request: SKRequest, didFailWithError error: Error) {
		callback(error)
	}
}

