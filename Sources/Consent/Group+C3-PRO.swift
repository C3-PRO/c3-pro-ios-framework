//
//  Group+C3-PRO.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 23/10/15.
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


/**
Extension to `SMART.GroupCharacteristic` so they can easily be used as an eligibility requirement.
*/
public extension GroupCharacteristic {
	
	/**
	Represents the `code.text` property (which is required) in an eligibility requirement.
	
	Currently only understands `valueBoolean`. If `valueBoolean` is true and `exclude` is false, a classic _inclusion_ criterion is
	represented. If `valueBoolean` is true and `exclude` is also true, a classic _exclusion_ criterion is represented. `valueBoolean` is
	false, the meaning reverses.
	*/
	public func c3_asEligibilityRequirement() -> EligibilityRequirement? {
		if let text = code?.text?.string, let exclude = exclude {
			let include = valueBoolean ?? true
			return EligibilityRequirement(title: text, mustBeMet: include.bool != exclude.bool)
		}
		return nil
	}
}

