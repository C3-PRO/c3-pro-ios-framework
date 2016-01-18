//
//  String+C3-PRO.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/16/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import Foundation


extension String {
	
	/// Convenience getter for localized strings, uses `NSLocalizedString` internally on the main bundle and the "C3PRO" table.
	public var c3_localized: String {
		return NSLocalizedString(self, tableName: "C3PRO", bundle: NSBundle.mainBundle(), value: self, comment: "")
	}
	
	/** Convenience method for string localizations that have a comment. */
	public func c3_localized(comment: String) -> String {
		return NSLocalizedString(self, tableName: "C3PRO", bundle: NSBundle.mainBundle(), value: self, comment: comment)
	}
}
