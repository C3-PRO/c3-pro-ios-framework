//
//  HealthKit+Convenience.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 11/28/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import HealthKit


extension HKBiologicalSex {
	
	/// Human readable strings: "Male", "Female", "Other" and "Not Set".
	var humanString: String {
		switch self {
		case .male:
			return "Male".c3_localized
		case .female:
			return "Female".c3_localized
		case .other:
			return "Other".c3_localized("Other sex")
		case .notSet:
			return "Not Set".c3_localized("Sex not set")
		}
	}
}

