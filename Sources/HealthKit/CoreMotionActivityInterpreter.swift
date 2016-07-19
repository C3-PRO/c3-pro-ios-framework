//
//  CoreMotionActivityInterpreter.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 15/07/16.
//  Copyright © 2016 University Hospital Zurich. All rights reserved.
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

import CoreMotion


public protocol CoreMotionActivityInterpreter {
	
	/**
	This method must be implemented and should do lightweight preprocessing of raw CMMotionActivity, as returned from
	CMMotionActivityManager, and pack them into CoreMotionActivity instances. The returned array is expected to contain all activities
	in order, oldest to newest.
	
	- parameter activities: The activities to preprocess
	- returns: Preprocessed and packaged motion activities
	*/
	func preprocess(activities activities: [CMMotionActivity]) -> [CoreMotionActivity]
	
	/**
	
	*/
	func interpret(activities activities: [InterpretedCoreMotionActivity]) -> [InterpretedCoreMotionActivity]
}
