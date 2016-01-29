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
An ordered task subclass that can inspect `ConditionalQuestionStep` instances' requirements and skip past questions in case the requirements
are not met.
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


class ConditionalQuestionStep: ORKQuestionStep {
	
	/// The original "type", specified in the FHIR Questionnaire.
	var fhirType: String?
	
	/// Requirements to fulfil for the step to show up, if any.
	var requirements: [ResultRequirement]?
	
	
	/**
	Designated initializer.
	
	- parameter identifier: The step identifier
	- parameter title: The step's title
	- parameter answer: The step's answer format
	*/
	init(identifier: String, title ttl: String?, answer: ORKAnswerFormat) {
		super.init(identifier: identifier)
		title = ttl
		answerFormat = answer
	}
	
	
	// MARK: - Requirements
	
	func addRequirement(requirement: ResultRequirement) {
		if nil == requirements {
			requirements = [ResultRequirement]()
		}
		requirements!.append(requirement)
	}
	
	func addRequirements(requirements reqs: [ResultRequirement]) {
		if nil == requirements {
			requirements = reqs
		}
		else {
			requirements!.appendContentsOf(reqs)
		}
	}
	
	/**
	If the step has requirements, checks if all of them are fulfilled in step results in the given task result.
	
	- parameter result: The result to use for the checks
	- returns: A bool indicating success or failure, nil if there are no requirements
	*/
	func requirementsAreSatisfiedBy(result: ORKTaskResult) -> Bool? {
		guard let requirements = requirements else {
			return nil
		}
		
		// check each requirement and drop out early if one fails
		for requirement in requirements {
			if let stepResult = result.resultForIdentifier(requirement.questionIdentifier as String) as? ORKStepResult {
				if let questionResults = stepResult.results as? [ORKQuestionResult] {
					var ok = false
					for questionResult in questionResults {
						//chip_logIfDebug("===>  \(questionResult.identifier) is \(questionResult.answer), needs to be \(requirement.result.answer): \(questionResult.chip_hasSameAnswer(requirement.result))")
						if questionResult.chip_hasSameAnswer(requirement.result) {
							ok = true
						}
					}
					if !ok {
						return false
					}
				}
				else {
					chip_logIfDebug("Expecting Array<ORKQuestionResult> but got \(stepResult.results)")
				}
			}
			else {
				chip_logIfDebug("Next step \(identifier) has a condition on \(requirement.questionIdentifier), but the latter has no result yet")
			}
		}
		return true
	}
	
	
	// MARK: - NSCopying
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		super.copyWithZone(zone)
		return self
	}
	
	
	// MARK: - NSSecureCoding
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		let set = NSSet(array: [NSArray.self, ResultRequirement.self]) as Set<NSObject>
		requirements = aDecoder.decodeObjectOfClasses(set, forKey: "requirements") as? [ResultRequirement]
	}
	
	override func encodeWithCoder(aCoder: NSCoder) {
		super.encodeWithCoder(aCoder)
		aCoder.encodeObject(requirements, forKey: "requirements")
	}
}


/**
A conditional instruction step, to be used in the conditional ordered task.
*/
class ConditionalInstructionStep: ORKInstructionStep {
	
	/// Requirements to fulfil for the step to show up, if any.
	var requirements: [ResultRequirement]?
	
	/**
	Designated initializer.
	
	- parameter identifier: The step's identifier
	- parameter title: The step's title
	- parameter text: The instruction text
	*/
	init(identifier: String, title ttl: String?, text txt: String?) {
		super.init(identifier: identifier)
		title = ttl
		text = txt
	}
	
	
	// MARK: - Requirements
	
	func addRequirement(requirement: ResultRequirement) {
		if nil == requirements {
			requirements = [ResultRequirement]()
		}
		requirements!.append(requirement)
	}
	
	func addRequirements(requirements reqs: [ResultRequirement]) {
		if nil == requirements {
			requirements = reqs
		}
		else {
			requirements!.appendContentsOf(reqs)
		}
	}
	
	/**
	If the step has requirements, checks if all of them are fulfilled in step results in the given task result.
	
	- returns: A bool indicating success or failure, nil if there are no requirements
	*/
	func requirementsAreSatisfiedBy(result: ORKTaskResult) -> Bool? {
		guard let requirements = requirements else {
			return nil
		}
		
		// check each requirement and drop out early if one fails
		for requirement in requirements {
			if let stepResult = result.resultForIdentifier(requirement.questionIdentifier as String) as? ORKStepResult {
				if let questionResults = stepResult.results as? [ORKQuestionResult] {
					var ok = false
					for questionResult in questionResults {
						//chip_logIfDebug("===>  \(questionResult.identifier) is \(questionResult.answer), needs to be \(requirement.result.answer): \(questionResult.chip_hasSameAnswer(requirement.result))")
						if questionResult.chip_hasSameAnswer(requirement.result) {
							ok = true
						}
					}
					if !ok {
						return false
					}
				}
				else {
					chip_logIfDebug("Expecting Array<ORKQuestionResult> but got \(stepResult.results)")
				}
			}
			else {
				chip_logIfDebug("Next step \(identifier) has a condition on \(requirement.questionIdentifier), but the latter has no result yet")
			}
		}
		return true
	}
	
	
	// MARK: - NSCopying
	
	override func copyWithZone(zone: NSZone) -> AnyObject {
		super.copyWithZone(zone)
		return self
	}
	
	
	// MARK: - NSSecureCoding
	
	required init(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		let set = NSSet(array: [NSArray.self, ResultRequirement.self]) as Set<NSObject>
		requirements = aDecoder.decodeObjectOfClasses(set, forKey: "requirements") as? [ResultRequirement]
	}
	
	override func encodeWithCoder(aCoder: NSCoder) {
		super.encodeWithCoder(aCoder)
		aCoder.encodeObject(requirements, forKey: "requirements")
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


// MARK: -

extension ORKQuestionResult {
	
	/**
	Checks whether the receiver is the same result as the other result.
	
	- parameter other: The result to compare against
	- returns: A boold indicating whether the results are the same
	*/
	func chip_hasSameAnswer(other: ORKQuestionResult) -> Bool {
		if let myAnswer: AnyObject = answer {
			if let otherAnswer: AnyObject = other.answer {
				return myAnswer.isEqual(otherAnswer)
			}
		}
		return false
	}
}

