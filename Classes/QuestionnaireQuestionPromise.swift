//
//  QuestionnaireQuestionPromise.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 4/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SwiftFHIR
import ResearchKit


/**
	A promise that can fulfill a questionnaire question into an ORKQuestionStep.
 */
class QuestionnaireQuestionPromise: QuestionnairePromiseProto
{
	/// The promises' question.
	let question: QuestionnaireGroupQuestion
	
	/// The step(s), internally assigned after the promise has been successfully fulfilled.
	internal(set) var steps: [ORKStep]?
	
	init(question: QuestionnaireGroupQuestion) {
		self.question = question
	}
	
	
	// MARK: - Fulfilling
	
	/** Fulfill the promise.
		
		Once the promise has been successfully fulfilled, the `step` property will be assigned. No guarantees as to on
		which queue the callback will be called.

		:param: callback The callback to be called when done; note that even when you get an error, some steps might
			have successfully been allocated still, so don't throw everything away just because you receive errors
	 */
	func fulfill(callback: ((errors: [NSError]?) -> Void)) {
		let linkId = question.linkId ?? NSUUID().UUIDString
		let title = question.chip_bestTitle()
		let text = nil != title ? nil : question.text
		
		// resolve answer format, THEN resolve sub-groups, if any
		answerFormatForQuestion(question) { format, berror in
			var steps = [ORKStep]()
			var errors = [NSError]()
			
			if let fmt = format {
				let step = ORKQuestionStep(identifier: linkId, title: title, answer: fmt)
				step.text = text
				step.optional = !(self.question.required ?? false)
				steps.append(step)
			}
			else {
				errors.append(berror ?? createQuestionnaireError("Failed to map question type to ResearchKit answer format"))
			}
			
			// do we have sub-groups?
			if let subgroups = self.question.group {
				var gpromises = [QuestionnaireGroupPromise]()
				for subgroup in subgroups {
					gpromises.append(QuestionnaireGroupPromise(group: subgroup))
				}
				
				// fulfill all group promises
				let queueGroup = dispatch_group_create()
				for gpromise in gpromises {
					dispatch_group_enter(queueGroup)
					gpromise.fulfill() { berrors in
						if nil != berrors {
							errors.extend(berrors!)
						}
						dispatch_group_leave(queueGroup)
					}
				}
				
				// all done
				dispatch_group_notify(queueGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
					let gsteps = gpromises.filter() { return nil != $0.steps }.flatMap() { return $0.steps! }
					steps.extend(gsteps)
					
					self.steps = steps
					callback(errors: count(errors) > 0 ? errors : nil)
				}
			}
			else {
				self.steps = steps
				callback(errors: errors)
			}
		}
	}
	
	
	// MARK: - Answer Processing
	
	/** Determine ResearchKit's answer format for the question type.
	
		TODO: "open-choice" allows to choose an option OR to give a textual response; implement
	 */
	func answerFormatForQuestion(question: QuestionnaireGroupQuestion, callback: ((format: ORKAnswerFormat?, error: NSError?) -> Void)) {
		if let type = question.type {
			switch type {
				case "boolean":		callback(format: ORKAnswerFormat.booleanAnswerFormat(), error: nil)
				case "decimal":		callback(format: ORKAnswerFormat.decimalAnswerFormatWithUnit(nil), error: nil)
				case "integer":		callback(format: ORKAnswerFormat.integerAnswerFormatWithUnit(nil), error: nil)
				case "quantity":	callback(format: ORKAnswerFormat.decimalAnswerFormatWithUnit(nil), error: nil)		// TODO: add unit
				case "date":		callback(format: ORKAnswerFormat.dateAnswerFormat(), error: nil)
				case "dateTime":	callback(format: ORKAnswerFormat.dateTimeAnswerFormat(), error: nil)
				case "instant":		callback(format: ORKAnswerFormat.dateTimeAnswerFormat(), error: nil)
				case "time":		callback(format: ORKAnswerFormat.timeOfDayAnswerFormat(), error: nil)
				case "string":		callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
				case "url":			callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
				case "choice":
					answerChoicesForQuestion(question) { choices, error in
						if nil != error || nil == choices {
							callback(format: nil, error: error ?? createQuestionnaireError("There are no choices in question «\(question.text)»"))
						}
						else {
							callback(format: ORKAnswerFormat.choiceAnswerFormatWithStyle(.SingleChoice, textChoices: choices!), error: nil)
						}
					}
				case "open-choice":
					answerChoicesForQuestion(question) { choices, error in
						if nil != error || nil == choices {
							callback(format: nil, error: error ?? createQuestionnaireError("There are no choices in question «\(question.text)»"))
						}
						else {
							callback(format: ORKAnswerFormat.choiceAnswerFormatWithStyle(.SingleChoice, textChoices: choices!), error: nil)
						}
					}
				//case "attachment":	callback(format: nil, error: nil)
				//case "reference":		callback(format: nil, error: nil)
				default:
					callback(format: nil, error: createQuestionnaireError("Cannot map question type \"\(type)\" to ResearchKit answer format"))
			}
		}
		else {
			NSLog("Question «\(question.text)» does not have an answer type, assuming text answer")
			callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
		}
	}
	
	/** For `choice` type questions, retrieves the possible answers and returns them as ORKTextChoice in the callback. */
	func answerChoicesForQuestion(question: QuestionnaireGroupQuestion, callback: ((choices: [ORKTextChoice]?, error: NSError?) -> Void)) {
		question.options?.resolve(ValueSet.self) { valueSet in
			var choices = [ORKTextChoice]()
			
			// valueset defines its own concepts
			if let options = valueSet?.define?.concept {
				for option in options {
					let code = option.code ?? ""				// code is a required property, so SHOULD always be present
					let text = ORKTextChoice(text: option.display ?? code, value: code)
					choices.append(text)
				}
			}
			
			// valueset includes codes
			if let options = valueSet?.compose?.include {		// TODO: also support `import`
				for option in options {
					if let concepts = option.concept {
						for concept in concepts {
							let code = concept.code ?? ""		// code is a required property, so SHOULD always be present
							let text = ORKTextChoice(text: concept.display ?? code, value: code)
							choices.append(text)
						}
					}
				}
			}
			
			// all done
			if count(choices) > 0 {
				callback(choices: choices, error: nil)
			}
			else {
				callback(choices: nil, error: createQuestionnaireError("Question «\(question.text)» does not specify choices in its ValueSet"))
			}
		}
	}
	
	
	// MARK: - Printable
	
	var description: String {
		return NSString(format: "<QuestionnaireQuestionPromise %p>", unsafeAddressOf(self)) as String
	}
}


extension QuestionnaireGroupQuestion
{
	func chip_bestTitle() -> String? {
		let cDisplay = concept?.filter() { return nil != $0.display }.map() { return $0.display! }
		let cCodes = concept?.filter() { return nil != $0.code }.map() { return $0.code! }
		
		return cDisplay?.first ?? (cCodes?.first ?? text?.chip_stripMultipleSpaces())
	}
}

