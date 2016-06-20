//
//  QuestionnaireItemPromise.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 4/20/15.
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
import SMART
import ResearchKit


let kORKTextChoiceSystemSeparator: Character = " "
let kORKTextChoiceDefaultSystem = "https://fhir.smalthealthit.org"
let kORKTextChoiceMissingCodeCode = "⚠️"


/**
A promise that can fulfill a questionnaire question into an ORKQuestionStep.
*/
class QuestionnaireItemPromise: QuestionnairePromiseProto {
	
	/// The promises' item.
	let item: QuestionnaireItem
	
	/// The step(s), internally assigned after the promise has been successfully fulfilled.
	internal(set) var steps: [ORKStep]?
	
	
	/**
	Designated initializer.
	
	- parameter question: The question the receiver represents
	*/
	init(item: QuestionnaireItem) {
		self.item = item
	}
	
	
	// MARK: - Fulfilling
	
	/**
	Fulfill the promise.
	
	Once the promise has been successfully fulfilled, the `step` property will be assigned. No guarantees as to on which queue the callback
	will be called.
	
	- parameter parentRequirements: Requirements from the parent that must be inherited
	- parameter callback: The callback to be called when done; note that even when you get an error, some steps might have successfully been
	                      allocated still, so don't throw everything away just because you receive errors
	*/
	func fulfill(parentRequirements: [ResultRequirement]?, callback: ((errors: [ErrorType]?) -> Void)) {
		let linkId = item.linkId ?? NSUUID().UUIDString
		let (title, text) = item.c3_bestTitleAndText()
		
		// resolve answer format, THEN resolve sub-groups, if any
		item.c3_asAnswerFormat() { format, error in
			var steps = [ORKStep]()
			var errors = [ErrorType]()
			var requirements = parentRequirements ?? [ResultRequirement]()
			
			// we know the answer format, create a conditional step
			if let fmt = format {
				let step = ConditionalQuestionStep(identifier: linkId, title: title, answer: fmt)
				step.fhirType = self.item.type
				step.text = text
				step.optional = !(self.item.required ?? false)
				
				// questions "enableWhen" requirements
				do {
					if let myreqs = try self.item.c3_enableQuestionnaireElementWhen() {
						requirements.appendContentsOf(myreqs)
					}
				}
				catch let error {
					errors.append(error)
				}
				
				if !requirements.isEmpty {
					step.addRequirements(requirements: requirements)
				}
				steps.append(step)
			}
			else if let error = error {
				errors.append(error)
			}
				
			// no error and no answer format but title and text - must be "display" or "group" item that has something to show!
			else if nil != title || nil != text {
				let step = ConditionalInstructionStep(identifier: linkId, title: title, text: text)
				steps.append(step)
			}
			
			// do we have sub-groups?
			if let subitems = self.item.item {
				let subpromises = subitems.map() { QuestionnaireItemPromise(item: $0) }
				
				// fulfill all group promises
				let queueGroup = dispatch_group_create()
				for subpromise in subpromises {
					dispatch_group_enter(queueGroup)
					subpromise.fulfill(requirements) { berrors in
						if nil != berrors {
							errors.appendContentsOf(berrors!)
						}
						dispatch_group_leave(queueGroup)
					}
				}
				
				// all done
				dispatch_group_notify(queueGroup, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
					let gsteps = subpromises.filter() { return nil != $0.steps }.flatMap() { return $0.steps! }
					steps.appendContentsOf(gsteps)
					
					self.steps = steps
					callback(errors: errors.count > 0 ? errors : nil)
				}
			}
			else {
				self.steps = steps
				callback(errors: errors)
			}
		}
	}
	
	
	// MARK: - Printable
	
	/// String representation of the receiver.
	var description: String {
		return NSString(format: "QuestionnaireItemPromise <%p>", unsafeAddressOf(self)) as String
	}
}


// MARK: -


extension QuestionnaireItem {
	
	/**
	Attempts to create a nice title and text from the various fields of the group.
	
	- returns: A tuple of strings for title and text
	*/
	func c3_bestTitleAndText() -> (String?, String?) {
		let cDisplay = concept?.filter() { return nil != $0.display }.map() { return $0.display! }
		let cCodes = concept?.filter() { return nil != $0.code }.map() { return $0.code! }
		
		var ttl = cDisplay?.first ?? cCodes?.first
		var txt = text
		
		if nil == ttl {
			ttl = text
			txt = nil
		}
		if nil == txt {
			txt = c3_questionInstruction() ?? c3_questionHelpText()		// even if the title is still nil, we won't want to populate the title with help text
		}
		
		return (ttl?.c3_stripMultipleSpaces(), txt?.c3_stripMultipleSpaces())
	}
	
	func c3_questionMinOccurs() -> Int? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-minOccurs")?.first?.valueInteger
	}
	
	func c3_questionMaxOccurs() -> Int? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-maxOccurs")?.first?.valueInteger
	}
	
	func c3_questionInstruction() -> String? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-instruction")?.first?.valueString
	}
	
	func c3_questionHelpText() -> String? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-help")?.first?.valueString
	}
	
	func c3_numericAnswerUnit() -> String? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-units")?.first?.valueString
	}
	
	func c3_defaultAnswer() -> Extension? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-defaultValue")?.first
	}
	
	
	/**
	Determine ResearchKit's answer format for the question type.
	
	Questions are multiple choice if "repeats" is set to true and the "max-occurs" extension is either not defined or larger than 1. See
	`c3_answerChoiceStyle`.
	
	TODO: "open-choice" allows to choose an option OR to give a textual response: implement
	
	[x] ORKScaleAnswerFormat:           "integer" plus min- and max-values defined, where max > min
	[ ] ORKContinuousScaleAnswerFormat:
	[ ] ORKValuePickerAnswerFormat:
	[ ] ORKImageChoiceAnswerFormat:
	[x] ORKTextAnswerFormat:            "string", "url"
	[x] ORKTextChoiceAnswerFormat:      "choice", "choice-open" (!)
	[x] ORKBooleanAnswerFormat:         "boolean"
	[x] ORKNumericAnswerFormat:         "decimal", "integer", "quantity"
	[x] ORKDateAnswerFormat:            "date", "dateTime", "instant"
	[x] ORKTimeOfDayAnswerFormat:       "time"
	[ ] ORKTimeIntervalAnswerFormat:
	*/
	func c3_asAnswerFormat(callback: ((format: ORKAnswerFormat?, error: ErrorType?) -> Void)) {
		let link = linkId ?? "<nil>"
		if let type = type {
			switch type {
			case "boolean":	  callback(format: ORKAnswerFormat.booleanAnswerFormat(), error: nil)
			case "decimal":	  callback(format: ORKAnswerFormat.decimalAnswerFormatWithUnit(nil), error: nil)
			case "integer":
				let minVals = c3_minValue()
				let maxVals = c3_maxValue()
				let minVal = minVals?.filter() { return $0.valueInteger != nil }.first?.valueInteger
				let maxVal = maxVals?.filter() { return $0.valueInteger != nil }.first?.valueInteger
				if let minVal = minVal, maxVal = maxVal where maxVal > minVal {
					let minDesc = minVals?.filter() { return $0.valueString != nil }.first?.valueString
					let maxDesc = maxVals?.filter() { return $0.valueString != nil }.first?.valueString
					let defVal = c3_defaultAnswer()?.valueInteger ?? minVal
					let format = ORKAnswerFormat.scaleAnswerFormatWithMaximumValue(maxVal, minimumValue: minVal, defaultValue: defVal,
						step: 1, vertical: (maxVal - minVal > 5),
						maximumValueDescription: maxDesc, minimumValueDescription: minDesc)
					callback(format: format, error: nil)
					
				}
				else {
					callback(format: ORKAnswerFormat.integerAnswerFormatWithUnit(nil), error: nil)
				}
			case "quantity":  callback(format: ORKAnswerFormat.decimalAnswerFormatWithUnit(c3_numericAnswerUnit()), error: nil)
			case "date":      callback(format: ORKAnswerFormat.dateAnswerFormat(), error: nil)
			case "dateTime":  callback(format: ORKAnswerFormat.dateTimeAnswerFormat(), error: nil)
			case "instant":   callback(format: ORKAnswerFormat.dateTimeAnswerFormat(), error: nil)
			case "time":      callback(format: ORKAnswerFormat.timeOfDayAnswerFormat(), error: nil)
			case "string":    callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
			case "url":       callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
			case "choice":
				c3_resolveAnswerChoices() { choices, error in
					if nil != error || nil == choices {
						callback(format: nil, error: error ?? C3Error.QuestionnaireNoChoicesInChoiceQuestion(self))
					}
					else {
						callback(format: ORKAnswerFormat.choiceAnswerFormatWithStyle(self.c3_answerChoiceStyle(), textChoices: choices!), error: nil)
					}
				}
			case "open-choice":
				c3_resolveAnswerChoices() { choices, error in
					if nil != error || nil == choices {
						callback(format: nil, error: error ?? C3Error.QuestionnaireNoChoicesInChoiceQuestion(self))
					}
					else {
						callback(format: ORKAnswerFormat.choiceAnswerFormatWithStyle(self.c3_answerChoiceStyle(), textChoices: choices!), error: nil)
					}
				}
			//case "attachment":	callback(format: nil, error: nil)
			//case "reference":		callback(format: nil, error: nil)
			case "display":
				callback(format: nil, error: nil)
			case "group":
				callback(format: nil, error: nil)
			default:
				callback(format: nil, error: C3Error.QuestionnaireQuestionTypeUnknownToResearchKit(self))
			}
		}
		else {
			NSLog("Question «\(text)» does not have an answer type, assuming text answer [linkId: \(link)]")
			callback(format: ORKAnswerFormat.textAnswerFormat(), error: nil)
		}
	}
	
	/**
	For `choice` type questions, retrieves the possible answers and returns them as ORKTextChoice in the callback.
	
	The `value` property of the text choice is a combination of the coding system URL and the code, separated by
	`kORKTextChoiceSystemSeparator` (a space). If no system URL is provided, "https://fhir.smalthealthit.org" is used.
	*/
	func c3_resolveAnswerChoices(callback: ((choices: [ORKTextChoice]?, error: ErrorType?) -> Void)) {
		options?.resolve(ValueSet.self) { valueSet in
			var choices = [ORKTextChoice]()
			
			// we have an expanded ValueSet
			if let expansion = valueSet?.expansion?.contains {
				for option in expansion {
					let system = option.system?.absoluteString ?? kORKTextChoiceDefaultSystem
					let code = option.code ?? kORKTextChoiceMissingCodeCode
					let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
					let text = ORKTextChoice(text: option.display ?? code, value: value)
					choices.append(text)
				}
			}
			
			// valueset includes or defines codes
			else if let compose = valueSet?.compose {
				if let options = compose.include {
					for option in options {
						let system = option.system?.absoluteString ?? kORKTextChoiceDefaultSystem	// system is a required property
						if let concepts = option.concept {
							for concept in concepts {
								let code = concept.code ?? kORKTextChoiceMissingCodeCode	// code is a required property, so SHOULD always be present
								let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
								let text = ORKTextChoice(text: concept.display ?? code, value: value)
								choices.append(text)
							}
						}
					}
				}
				// TODO: also support `import`
			}
			
			// all done
			if choices.count > 0 {
				callback(choices: choices, error: nil)
			}
			else {
				callback(choices: nil, error: C3Error.QuestionnaireNoChoicesInChoiceQuestion(self))
			}
		}
	}
	
	/**
	For `choice` type questions, inspect if the given question is single or multiple choice. Questions are multiple choice if "repeats" is
	true and the "max-occurs" extension is either not defined or larger than 1.
	*/
	func c3_answerChoiceStyle() -> ORKChoiceAnswerStyle {
		let multiple = repeats ?? ((c3_questionMaxOccurs() ?? 1) > 1)
		let style: ORKChoiceAnswerStyle = multiple ? .MultipleChoice : .SingleChoice
		return style
	}
}

