//
//  String+C3-PRO.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/16/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
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
