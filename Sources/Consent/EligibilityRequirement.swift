//
//  EligibilityRequirement.swift
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


/**
Objects holding and tracking eligibility requirements.
*/
public class EligibilityRequirement {
	
	/// The question/statement to show when asking about this requirement.
	public let title: String
	
	/// Whether this requirement must be met.
	public var mustBeMet = true
	
	/// Whether this requirement has been met.
	public var met: Bool? = nil
	
	public init(title: String, mustBeMet: Bool = true) {
		self.title = title
		self.mustBeMet = mustBeMet
	}
}

