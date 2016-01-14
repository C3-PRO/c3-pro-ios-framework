//
//  EligibilityRequirement.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 23/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
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

