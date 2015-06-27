//
//  ORKTaskResult+FHIR.swift
//  ResearchCHIP
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
				println("->  \(result.identifier)  \(result)")
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
	func chip_questionAnswers(task: ORKTask?) -> QuestionnaireAnswersGroup? {
		if let results = results as? [ORKResult] {
			let group = QuestionnaireAnswersGroup(json: nil)
			var questions = [QuestionnaireAnswersGroupQuestion]()
			
			// loop results to collect answers
			for result in results {
				if let result = result as? ORKQuestionResult {
					
					let question = QuestionnaireAnswersGroupQuestion(json: nil)
					question.linkId = result.identifier
					question.answer = result.chip_answerAsQuestionAnswersOfStep(task?.stepWithIdentifier?(result.identifier))
					questions.append(question)
				}
				else {
					println("xx>  Cannot handle ORKStepResult result \(result)")
				}
			}
			
			group.question = questions
			return group
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
	func chip_answerAsQuestionAnswersOfStep(step: ORKStep?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		let fhirType = (step as? ConditionalQuestionStep)?.fhirType
		println("-->  \(identifier)  \(self)")
		println("-->  FHIR: \(fhirType)")
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
		println("xx>  Don't understand ORKQuestionResult answer from \(self)")
		return nil
	}
}


extension ORKChoiceQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let choices = choiceAnswers {
			println("--->  \(choices)")
		}
		return nil
	}
}


extension ORKTextQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let text = textAnswer {
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			answer.valueString = text
			return [answer]
		}
		return nil
	}
}


extension ORKNumericQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let numeric = numericAnswer {
			println("--->  \(numeric)")
			println("---->  \(unit)")
			let answer = QuestionnaireAnswersGroupQuestionAnswer(json: nil)
			if let unit = unit {
				answer.valueQuantity = Quantity(json: nil)
				answer.valueQuantity!.value = NSDecimalNumber(json: numeric)
				answer.valueQuantity!.units = unit
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
			answer.valueTime = Time(hour: UInt8(components.hour), minute: UInt8(components.minute), second: Double(components.second))
			return [answer]
		}
		return nil
	}
}


extension ORKTimeIntervalQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let interval = intervalAnswer {
			println("--->  \(interval)")
		}
		return nil
	}
}


extension ORKDateQuestionResult
{
	func chip_asQuestionAnswers(fhirType: String?) -> [QuestionnaireAnswersGroupQuestionAnswer]? {
		if let date = dateAnswer {
			println("--->  \(date)")
			println("---->  \(calendar)")
			println("---->  \(timeZone)")
		}
		return nil
	}
}

