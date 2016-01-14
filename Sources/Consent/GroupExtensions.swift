//
//  GroupExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 23/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import SMART


public extension GroupCharacteristic {
	
	/**
	Represents the `code.text` property (which is required) in an eligibility requirement.
	
	Currently only understands `valueBoolean`. If `valueBoolean` is true and `exclude` is false, a classic _inclusion_ criterion is
	represented. If `valueBoolean` is true and `exclude` is also true, a classic _exclusion_ criterion is represented. `valueBoolean` is
	false, the meaning reverses.
	*/
	public func chip_asEligibilityRequirement() -> EligibilityRequirement? {
		if let text = code?.text, let exclude = exclude {
			let include = valueBoolean ?? true
			return EligibilityRequirement(title: text, mustBeMet: include != exclude)
		}
		return nil
	}
}

