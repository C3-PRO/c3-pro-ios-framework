//
//  ORKTaskResult+FHIR.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 6/26/15.
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

import ResearchKit
import SMART


/**
Extend ORKTaskResult to add functionality to convert to QuestionnaireResponse.
*/
extension ORKTaskResult {
	
	/**
	Extracts all results from the task and converts them to a FHIR QuestionnaireResponse.
	
	- parameter task: The task the receiver is a result for
	- returns: A `QuestionnaireResponse` resource or nil
	*/
	func c3_asQuestionnaireResponseForTask(task: ORKTask?) -> QuestionnaireResponse? {
		guard let results = results as? [ORKStepResult] else {
			return nil
		}
		var groups = [QuestionnaireResponseGroup]()
		
		// loop results to collect groups
		for result in results {
			if let group = result.c3_questionAnswers(task) {
				groups.append(group)
			}
		}
		
		// create top-level group to hold all groups
		let master = QuestionnaireResponseGroup(json: nil)
		master.group = groups
		
		// create and return questionnaire answers
		let questionnaire = Reference(json: nil)
		questionnaire.reference = identifier
		
		let answer = QuestionnaireResponse(status: "completed")
		answer.questionnaire = questionnaire
		answer.group = master
		return answer
	}
}


extension ORKStepResult {
	
	/**
	Creates a QuestionnaireResponseGroup resource from all ORKSteps in the given ORKTask. Questions that do not have answers will be omitted,
	and groups that do not have at least a single question with answer will likewise be omitted.
	
	- parameter task: The ORKTask the result belongs to
	- returns: A QuestionnaireResponseGroup element or nil
	*/
	func c3_questionAnswers(task: ORKTask?) -> QuestionnaireResponseGroup? {
		if let results = results {
			let group = QuestionnaireResponseGroup(json: nil)
			var questions = [QuestionnaireResponseGroupQuestion]()
			
			// loop results to collect answers; omit questions that do not have answers
			for result in results {
				if let result = result as? ORKQuestionResult,
					let answers = result.c3_answerAsQuestionAnswersOfStep(task?.stepWithIdentifier?(result.identifier) as? ORKQuestionStep) {
						let question = QuestionnaireResponseGroupQuestion(json: nil)
						question.linkId = result.identifier
						question.answer = answers
						questions.append(question)
				}
				else {
					c3_warn("I cannot handle ORKStepResult result \(result)")
				}
			}
			
			if questions.count > 0 {
				group.question = questions
				return group
			}
		}
		return nil
	}
}


extension ORKQuestionResult {
	
	/**
	Instantiate a QuestionnaireResponse.group.question.answer element from the receiver's answer, if any.
	
	TODO: Cannot override methods defined in extensions, hence we need to check for the ORKQuestionResult subclass and then call the
	method implemented in the extensions below.
	
	- parameter task: The ORKTask the result belongs to
	- returns: An array of question answers or nil
	*/
	func c3_answerAsQuestionAnswersOfStep(step: ORKQuestionStep?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		let fhirType = (step as? ConditionalQuestionStep)?.fhirType
		
		if let this = self as? ORKChoiceQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTextQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKNumericQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKScaleQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKBooleanQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTimeOfDayQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTimeIntervalQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKDateQuestionResult {
			return this.c3_asQuestionAnswers(fhirType)
		}
		c3_warn("I don't understand ORKQuestionResult answer from \(self)")
		return nil
	}
	
	/**
	Checks whether the receiver is the same result as the other result.
	
	- parameter other: The result to compare against
	- returns: A boold indicating whether the results are the same
	*/
	func c3_hasSameAnswer(other: ORKQuestionResult) -> Bool {
		if let myAnswer: AnyObject = answer {
			if let otherAnswer: AnyObject = other.answer {
				return myAnswer.isEqual(otherAnswer)
			}
		}
		return false
	}
}


extension ORKChoiceQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; ignored, always "coding"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let choices = choiceAnswers as? [String] else {
			c3_warn("expecting choice question results to be strings, but got: \(choiceAnswers)")
			return nil
		}
		var answers = [QuestionnaireResponseGroupQuestionAnswer]()
		for choice in choices {
			let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
			let splat = choice.characters.split() { $0 == kORKTextChoiceSystemSeparator }.map() { String($0) }
			let system = splat[0]
			let code = (splat.count > 1) ? splat[1..<splat.endIndex].joinWithSeparator(String(kORKTextChoiceSystemSeparator)) : kORKTextChoiceMissingCodeCode
			answer.valueCoding = Coding(json: ["system": system, "code": code])
			answers.append(answer)
		}
		return answers
	}
}


extension ORKTextQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; "url" or defaults to "string"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let text = textAnswer else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		if let fhir = fhirType where "url" == fhir {
			answer.valueUri = NSURL(string: text)
		}
		else {
			answer.valueString = text
		}
		return [answer]
	}
}


extension ORKNumericQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; "quantity", "integer" or defaults to "number"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let numeric = numericAnswer else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		if let fhir = fhirType where "quantity" == fhir {
			answer.valueQuantity = Quantity(json: ["value": numeric])
			answer.valueQuantity!.unit = unit
		}
		else if let fhir = fhirType where "integer" == fhir {
			answer.valueInteger = numeric.integerValue
		}
		else {
			answer.valueDecimal = NSDecimalNumber(json: numeric)
		}
		return [answer]
	}
}


extension ORKScaleQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; ignored, always "number"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let numeric = scaleAnswer else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		answer.valueDecimal = NSDecimalNumber(json: numeric)
		return [answer]
	}
}


extension ORKBooleanQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; ignored, always "boolean"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let boolean = booleanAnswer?.boolValue else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		answer.valueBoolean = boolean
		return [answer]
	}
}


extension ORKTimeOfDayQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; ignored, always "time"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let components = dateComponentsAnswer else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		answer.valueTime = Time(hour: UInt8(components.hour), minute: UInt8(components.minute), second: 0.0)
		return [answer]
	}
}


extension ORKTimeIntervalQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	TODO: implement!
	
	- parameter fhirType: The FHIR answer type that's expected; ignored, always "interval"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let interval = intervalAnswer else {
			return nil
		}
		//let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		// TODO: support interval answers
		print("--->  \(interval) for FHIR type “\(fhirType)”")
		return nil
	}
}


extension ORKDateQuestionResult {
	
	/**
	Creates question answers of the receiver.
	
	- parameter fhirType: The FHIR answer type that's expected; supports "date", "dateTime" (default) and "instant"
	- returns: An array of question answers or nil
	*/
	func c3_asQuestionAnswers(fhirType: String?) -> [QuestionnaireResponseGroupQuestionAnswer]? {
		guard let date = dateAnswer else {
			return nil
		}
		let answer = QuestionnaireResponseGroupQuestionAnswer(json: nil)
		switch fhirType ?? "dateTime" {
		case "date":
			answer.valueDate = date.fhir_asDate()
		case "dateTime":
			let dateTime = date.fhir_asDateTime()
//			if let tz = timeZone {
//				dateTime.timeZone = tz			// TODO: reported NSDate is in UTC, convert to the given time zone
//			}
			answer.valueDateTime = dateTime
		case "instant":
			let instant = date.fhir_asInstant()
//			if let tz = timeZone {
//				instant.timeZone = tz
//			}
			answer.valueInstant = instant
		default:
			c3_warn("unknown date-time FHIR type “\(fhirType!)”, treating as dateTime")
			let dateTime = date.fhir_asDateTime()
//			if let tz = timeZone {
//				dateTime.timeZone = tz
//			}
			answer.valueDateTime = dateTime
		}
		return [answer]
	}
}

