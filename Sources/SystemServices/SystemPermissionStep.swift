//
//  SystemPermissionStep.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import ResearchKit


/**
This step can be used to prompt the user for permissions to system services, such as CoreMotion, HealthKit and Notifications.
*/
public class SystemPermissionStep: ORKStep {
	
	public var services: [SystemService]?
	
	
	public override required init(identifier: String) {
		super.init(identifier: identifier)
	}
	
	public convenience init(identifier: String, permissions: [SystemService]) {
		self.init(identifier: identifier)
		self.services = permissions
	}
	
	public required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public override func copyWithZone(zone: NSZone) -> AnyObject {
		let copy = self.dynamicType.init(identifier: identifier)
		copy.services = services
		return copy
	}
	
	
	public class func stepViewControllerClass() -> AnyClass {
		return SystemPermissionStepViewController.self
	}
}
