//
//  ORKTaskResult+FHIR.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 6/26/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import ResearchKit
import SMART


/**
    Extend ORKTaskResult to add functionality to convert to QuestionnaireAnswers.
 */
extension ORKTaskResult
{
	func chip_asQuestionnaireAnswersForTask(task: ORKTask?) -> QuestionnaireAnswers? {
		if let results = results as? [ORKStepResult] {
			var groups = [QuestionnaireAnswersGroup]()
			
			// loop results to collect groups
			for result in results {
				if let group = result.chip_questionAnswers(task) {
					groups.append(group)
				}
			}
			
			// create top-level group to hold all groups
			let master = QuestionnaireAnswersGroup(json: nil)
			master.linkId = identifier
			master.group = groups
			
			// create and return answer
			let answer = QuestionnaireAnswers(status: "completed")
			answer.group = master
			return answer
		}
		return nil
	}
}


extension ORKStepResult
{
	/**
	Creates a QuestionnaireAnswersGroup resource from all ORKSteps in the given ORKTask. Questions that do not have answers will be omitted,
	and groups that do not have at least a single question with answer will likewise be omitted.
	
	:param: task The ORKTask to convert to a FHIR answer group
	:returns: A QuestionnaireAnswersGroup element or nil
	*/
	func chip_questionAnswers(task: ORKTask?) -> QuestionnaireAnswersGroup? {
		if let results = results as? [ORKResult] {
			let group = QuestionnaireAnswersGroup(json: nil)
			var questions = [QuestionnaireAnswersGroupQuestion]()
			
			// loop results to collect answers; omit questions that do not have answers
			for result in results {
				if let result = result as? ORKQuestionResult,
					let answers = result.chip_answerAsQuestionAnswersOfStep(task?.stepWithIdentifier?(result.identifier) as? ORKQuestionStep) {
						let question = QuestionnaireAnswersGroupQuestion(json: nil)
						question.linkId = result.identifier
						question.answer = answers
						questions.append(question)
				}
				else {
					chip_warn("I cannot handle ORKStepResult result \(result)")
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


extension ORKQuestionResult
{
	/**
	Instantiate a QuestionnaireAnswers.group.question.answer element from the receiver's answer, if any.
	
	TODO: Cannot override methods defined in extensions, hence we need to check for the ORKQuestionResult subclass and then call the
	method implemented in the extensions below.
	*/
	func chip_answerAsQuestionAnswersOfStep(step: ORKQuestionStep?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		let fhirType = (step as? ConditionalQuestionStep)?.fhirType
		
		if let this = self as? ORKChoiceQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTextQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKNumericQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKScaleQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKBooleanQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTimeOfDayQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKTimeIntervalQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		if let this = self as? ORKDateQuestionResult {
			return this.chip_asQuestionAnswers(fhirType)
		}
		chip_warn("I don't understand ORKQuestionResult answer from \(self)")
		return nil
	}
}


extension ORKChoiceQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let choices = choiceAnswers as? [String] {
			var answers = [QuestionnaireAnswersGroupQuestionAnswer]()
			for choice in choices {
				let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
				let splat = split(choice) { $0 == kORKTextChoiceSystemSeparator }
				let system = splat[0]
				let code = (splat.count > 1) ? "\(kORKTextChoiceSystemSeparator)".join(splat[1..<splat.endIndex]) : kORKTextChoiceMissingCodeCode
				answer.valueCoding = Coding(json: ["system": system, "code": code])
				answers.append(answer)
			}
			return answers
		}
		else {
			chip_warn("expecting choice question results to be strings, but got: \(choiceAnswers)")
		}
		return nil
	}
}


extension ORKTextQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let text = textAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			if let fhir = fhirType where "url" == fhir {
				answer.valueUri = NSURL(string: text)
			}
			else {
				answer.valueString = text
			}
			return [answer]
		}
		return nil
	}
}


extension ORKNumericQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let numeric = numericAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			if let fhir = fhirType where "quantity" == fhir {
				answer.valueQuantity = Quantity(json: ["value": numeric])
				answer.valueQuantity!.units = unit
			}
			else if let fhir = fhirType where "integer" == fhir {
				answer.valueInteger = numeric.integerValue
			}
			else {
				answer.valueDecimal = NSDecimalNumber(json: numeric)
			}
			return [answer]
		}
		return nil
	}
}


extension ORKScaleQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let numeric = scaleAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			answer.valueDecimal = NSDecimalNumber(json: numeric)
			return [answer]
		}
		return nil
	}
}


extension ORKBooleanQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let boolean = booleanAnswer?.boolValue {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			answer.valueBoolean = boolean
			return [answer]
		}
		return nil
	}
}


extension ORKTimeOfDayQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let components = dateComponentsAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			answer.valueTime = Time(hour: UInt8(components.hour), minute: UInt8(components.minute), second: 0.0)
			return [answer]
		}
		return nil
	}
}


extension ORKTimeIntervalQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let interval = intervalAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			// TODO: support interval answers
			println("--->  \(interval) for FHIR type “\(fhirType)”")
		}
		return nil
	}
}


extension ORKDateQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let date = dateAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			switch fhirType ?? "dateTime" {
			case "date":
				answer.valueDate = date.fhir_asDate()
			case "dateTime":
				var dateTime = date.fhir_asDateTime()
				if let tz = timeZone {
//					dateTime.timeZone = tz			// TODO: reported NSDate is in UTC, convert to the given time zone
				}
				answer.valueDateTime = dateTime
			case "instant":
				var instant = date.fhir_asInstant()
				if let tz = timeZone {
//					instant.timeZone = tz
				}
				answer.valueInstant = instant
			default:
				chip_warn("unknown date-time FHIR type “\(fhirType!)”, treating as dateTime")
				var dateTime = date.fhir_asDateTime()
				if let tz = timeZone {
//					dateTime.timeZone = tz
				}
				answer.valueDateTime = dateTime
			}
			return [answer]
		}
		return nil
	}
}

