//
//  SystemPermissionStep.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
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
