//
//  ConditionalOrderedTask.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/27/15.
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

import Foundation
import ResearchKit


/**
An ordered task subclass that can inspect `ConditionalQuestionStep` and `ConditionalInstructionStep` instances' requirements and skip past
questions in case the requirements are not met.

This class could potentially be replaced by using a `ORKNavigableOrderedTask` instead. The approach used in navibale task is different in
that one defines triggers to jump to different places, opposed to checking results for each step and then deciding whether to skip it or
not.
*/
class ConditionalOrderedTask: ORKOrderedTask {
	
	override func stepAfterStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
		let serialNext = super.stepAfterStep(step, withResult: result)
		
		// does the serial next step have conditional requirements and are they satisfied?
		if let condNext = serialNext as? ConditionalQuestionStep {
			if let ok = condNext.requirementsAreSatisfiedBy(result) where !ok {
				return stepAfterStep(condNext, withResult: result)
			}
		}
		if let condNext = serialNext as? ConditionalInstructionStep {
			if let ok = condNext.requirementsAreSatisfiedBy(result) where !ok {
				return stepAfterStep(condNext, withResult: result)
			}
		}
		return serialNext
	}
	
	override func stepBeforeStep(step: ORKStep?, withResult result: ORKTaskResult) -> ORKStep? {
		let serialPrev = super.stepBeforeStep(step, withResult: result)
		
		// does the serial previous step have conditional requirements and are they satisfied?
		if let condPrev = serialPrev as? ConditionalQuestionStep {
			if let ok = condPrev.requirementsAreSatisfiedBy(result) where !ok {
				return stepBeforeStep(condPrev, withResult: result)
			}
		}
		if let condPrev = serialPrev as? ConditionalInstructionStep {
			if let ok = condPrev.requirementsAreSatisfiedBy(result) where !ok {
				return stepBeforeStep(condPrev, withResult: result)
			}
		}
		return serialPrev
	}
}


/**
Encapsulates requirements for a result, to be used in the conditional task.
*/
public class ResultRequirement: NSObject, NSCopying, NSSecureCoding {
	
	/// The step identifier of the question we have an answer for.
	public var questionIdentifier: NSString
	
	/// The result to match.
	public var result: ORKQuestionResult
	
	
	/**
	Designated initializer.
	
	- parameter step: The step's identifier the receiver should be checked against
	- parameter result: The result to validate
	*/
	public init(step: String, result rslt: ORKQuestionResult) {
		questionIdentifier = step as NSString
		result = rslt
	}
	
	
	// MARK: - NSCopying
	
	public func copyWithZone(zone: NSZone) -> AnyObject {
		let step = questionIdentifier.copyWithZone(zone) as! String
		return ResultRequirement(step: step, result: result.copyWithZone(zone) as! ORKQuestionResult)
	}
	
	
	// MARK: - NSSecureCoding
	
	public class func supportsSecureCoding() -> Bool {
		return true
	}
	
	required public init?(coder aDecoder: NSCoder) {
		questionIdentifier = aDecoder.decodeObjectOfClass(NSString.self, forKey: "stepIdentifier")!
		result = aDecoder.decodeObjectOfClass(ORKQuestionResult.self, forKey: "result")!
	}
	
	public func encodeWithCoder(aCoder: NSCoder) {
		aCoder.encodeObject(questionIdentifier, forKey: "stepIdentifier")
		aCoder.encodeObject(result, forKey: "result")
	}
}

