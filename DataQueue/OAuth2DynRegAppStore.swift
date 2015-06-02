//
//  OAuth2DynRegAppStore.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 6/2/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import SMART


public class OAuth2DynRegAppStore: OAuth2DynReg
{
	public var sandbox = false
	
	
	override public func registrationBody() -> OAuth2JSON {
		var dict = super.registrationBody()
		dict["sandbox"] = sandbox
		dict["receipt-data"] = appReceipt()
		return dict
	}
	
	func appReceipt() -> String {
		if let receiptURL = NSBundle.mainBundle().appStoreReceiptURL {
			if let receipt = NSData(contentsOfURL: receiptURL) {
				return NSString(data: receipt, encoding: NSUTF8StringEncoding) as! String
			}
		}
		return "NO-APP-RECEIPT"
	}
}

