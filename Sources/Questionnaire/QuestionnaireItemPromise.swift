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
let kC3ValuePickerFormatExtensionURL = "http://fhir-registry.smarthealthit.org/StructureDefinition/value-picker"


/**
A promise that can fulfill a questionnaire question into an ORKQuestionStep.
*/
class QuestionnaireItemPromise: QuestionnairePromiseProto {
	
	/// The promises' item.
	let item: QuestionnaireItem
	
	/// Parent item, if any.
	weak var parent: QuestionnaireItemPromise?
	
	/// The step(s), internally assigned after the promise has been successfully fulfilled.
	internal(set) var steps: [ORKStep]?
	
	
	/**
	Designated initializer.
	
	- parameter question: The question the receiver represents
	*/
	init(item: QuestionnaireItem, parent: QuestionnaireItemPromise? = nil) {
		self.item = item
		self.parent = parent
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
	func fulfill(requiring parentRequirements: [ResultRequirement]?, callback: @escaping (([Error]?) -> Void)) {
		
		// resolve answer format, THEN resolve sub-groups, if any
		item.c3_asAnswerFormat() { format, error in
			var steps = [ORKStep]()
			var thisStep: ConditionalStep?
			var errors = [Error]()
			var requirements = parentRequirements ?? [ResultRequirement]()
			let (title, text) = self.item.c3_bestTitleAndText()
			
			// find item's "enableWhen" requirements
			do {
				if let myreqs = try self.item.c3_enableQuestionnaireElementWhen() {
					requirements.append(contentsOf: myreqs)
				}
			}
			catch let error {
				errors.append(error)
			}
			
			// we know the answer format, so this is a question, create a conditional step
			if let fmt = format {
				let step = ConditionalQuestionStep(identifier: self.linkId, linkIds: self.linkIds, title: title, answer: fmt)
				step.fhirType = self.item.type?.rawValue
				step.text = text
				step.isOptional = !(self.item.required ?? false)
				thisStep = step
			}
			else if let error = error {
				errors.append(error)
			}
				
			// no error and no answer format but title and text - must be "display" or "group" item that has something to show!
			else if nil != title || nil != text {
				thisStep = ConditionalInstructionStep(identifier: self.linkId, linkIds: self.linkIds, title: title, text: text)
			}
			
			// TODO: also look at "initial[x]" value and prepopulate
			
			// collect the step
			if var step = thisStep {
				if !requirements.isEmpty {
					step.add(requirements: requirements)
				}
				if let step = step as? ORKStep {
					steps.append(step)
				}
			}
			
			// do we have sub-groups?
			if let subitems = self.item.item {
				let subpromises = subitems.map() { QuestionnaireItemPromise(item: $0, parent: ("{root}" == self.linkId) ? nil : self) }
				
				// fulfill all group promises
				let queueGroup = DispatchGroup()
				for subpromise in subpromises {
					queueGroup.enter()
					subpromise.fulfill(requiring: requirements) { berrors in
						if nil != berrors {
							errors.append(contentsOf: berrors!)
						}
						queueGroup.leave()
					}
				}
				
				// all done
				queueGroup.notify(queue: DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated)) {
					let gsteps = subpromises.filter() { return nil != $0.steps }.flatMap() { return $0.steps! }
					steps.append(contentsOf: gsteps)
					
					self.steps = steps
					callback(errors.count > 0 ? errors : nil)
				}
			}
			else {
				self.steps = steps
				callback(errors)
			}
		}
	}
	
	
	// MARK: - Properties
	
	var linkId: String {
		return item.linkId?.string ?? UUID().uuidString
	}
	
	/// Returns an array of all linkIds of the parents down to the receiver.
	var linkIds: [String] {
		var ids = [String]()
		var prnt = parent
		while let parent = prnt {
			ids.append(parent.linkId)
			prnt = parent.parent
		}
		return ids
	}
	
	
	// MARK: - Printable
	
	/// String representation of the receiver.
	var description: String {
		return "<\(type(of: self))>"
	}
}


// MARK: -


extension QuestionnaireItem {
	
	/**
	Attempts to create a nice title and text from the various fields of the group.
	
	- returns: A tuple of strings for title and text
	*/
	func c3_bestTitleAndText() -> (String?, String?) {
		let cDisplay = code?.filter() { return nil != $0.display }.map() { return $0.display!.localized }
		let cCodes = code?.filter() { return nil != $0.code }.map() { return $0.code!.string }		// TODO: can these be localized?
		
		var ttl = cDisplay?.first ?? cCodes?.first
		var txt = text?.localized
		
		if nil == ttl {
			ttl = text?.localized
			txt = nil
		}
		if nil == txt {
			txt = c3_questionInstruction() ?? c3_questionHelpText()		// even if the title is still nil, we won't want to populate the title with help text
		}
		// TODO: Even if we have title and instructions, show help somewhere if present
		
		return (ttl?.c3_stripMultipleSpaces(), txt?.c3_stripMultipleSpaces())
	}
	
	func c3_questionMinOccurs() -> Int? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-minOccurs")?.first?.valueInteger?.int
	}
	
	func c3_questionMaxOccurs() -> Int? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-maxOccurs")?.first?.valueInteger?.int
	}
	
	func c3_questionInstruction() -> String? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-instruction")?.first?.valueString?.localized
	}
	
	func c3_questionHelpText() -> String? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-help")?.first?.valueString?.localized
	}
	
	func c3_numericAnswerUnit() -> String? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-units")?.first?.valueString?.localized
	}
	
	func c3_defaultAnswer() -> Extension? {
		return extensions(forURI: "http://hl7.org/fhir/StructureDefinition/questionnaire-defaultValue")?.first
	}
	
	
	/**
	Determine ResearchKit's answer format for the question type.
	
	Questions are multiple choice if "repeats" is set to true and the "max-occurs" extension is either not defined or larger than 1. See
	`c3_answerChoiceStyle`.
	
	TODO: "open-choice" allows to choose an option OR to give a textual response: implement
	
	[x] ORKScaleAnswerFormat:           "integer" plus min- and max-values defined, where max > min
	[ ] ORKContinuousScaleAnswerFormat:
	[x] ORKValuePickerAnswerFormat:     "choice" (not multiple) plus extension `kC3ValuePickerFormatExtensionURL` (bool)
	[ ] ORKImageChoiceAnswerFormat:
	[x] ORKTextAnswerFormat:            "string", "url"
	[x] ORKTextChoiceAnswerFormat:      "choice", "choice-open" (!)
	[x] ORKBooleanAnswerFormat:         "boolean"
	[x] ORKNumericAnswerFormat:         "decimal", "integer", "quantity"
	[x] ORKDateAnswerFormat:            "date", "dateTime", "instant"
	[x] ORKTimeOfDayAnswerFormat:       "time"
	[ ] ORKTimeIntervalAnswerFormat:
	*/
	func c3_asAnswerFormat(callback: @escaping ((ORKAnswerFormat?, Error?) -> Void)) {
		let link = linkId ?? "<nil>"
		if let type = type {
			switch type {
			case .boolean:	  callback(ORKAnswerFormat.booleanAnswerFormat(), nil)
			case .decimal:	  callback(ORKAnswerFormat.decimalAnswerFormat(withUnit: nil), nil)
			case .integer:
				let minVals = c3_minValue()
				let maxVals = c3_maxValue()
				let minVal = minVals?.filter() { return $0.valueInteger != nil }.first?.valueInteger?.int
				let maxVal = maxVals?.filter() { return $0.valueInteger != nil }.first?.valueInteger?.int
				if let minVal = minVal, let maxVal = maxVal, maxVal > minVal {
					let minDesc = minVals?.filter() { return $0.valueString != nil }.first?.valueString?.localized
					let maxDesc = maxVals?.filter() { return $0.valueString != nil }.first?.valueString?.localized
					let defVal = c3_defaultAnswer()?.valueInteger?.int ?? minVal
					let format = ORKAnswerFormat.scale(withMaximumValue: Int(maxVal), minimumValue: Int(minVal), defaultValue: Int(defVal),
						step: 1, vertical: (maxVal - minVal > 5),
						maximumValueDescription: maxDesc, minimumValueDescription: minDesc)
					callback(format, nil)
					
				}
				else {
					callback(ORKAnswerFormat.integerAnswerFormat(withUnit: nil), nil)
				}
			case .quantity:  callback(ORKAnswerFormat.decimalAnswerFormat(withUnit: c3_numericAnswerUnit()), nil)
			case .date:      callback(ORKAnswerFormat.dateAnswerFormat(), nil)
			case .dateTime:  callback(ORKAnswerFormat.dateTime(), nil)
			case .time:      callback(ORKAnswerFormat.timeOfDayAnswerFormat(), nil)
			case .string:    callback(ORKAnswerFormat.textAnswerFormat(), nil)
			case .url:       callback(ORKAnswerFormat.textAnswerFormat(), nil)
			case .choice:
				c3_resolveAnswerChoices() { choices, error in
					if nil != error || nil == choices {
						callback(nil, error ?? C3Error.questionnaireNoChoicesInChoiceQuestion(self))
					}
					else {
						let multiStyle = self.c3_answerChoiceStyle()
						if .multipleChoice != multiStyle, self.extensions(forURI: kC3ValuePickerFormatExtensionURL)?.first?.valueBoolean?.bool ?? false {
							callback(ORKAnswerFormat.valuePickerAnswerFormat(with: choices!), nil)
						}
						else {
							callback(ORKAnswerFormat.choiceAnswerFormat(with: multiStyle, textChoices: choices!), nil)
						}
					}
				}
			case .openChoice:
				c3_resolveAnswerChoices() { choices, error in
					if nil != error || nil == choices {
						callback(nil, error ?? C3Error.questionnaireNoChoicesInChoiceQuestion(self))
					}
					else {
						callback(ORKAnswerFormat.choiceAnswerFormat(with: self.c3_answerChoiceStyle(), textChoices: choices!), nil)
					}
				}
			//case .attachment:	callback(format: nil, error: nil)
			//case .reference:		callback(format: nil, error: nil)
			case .display:
				callback(nil, nil)
			case .group:
				callback(nil, nil)
			default:
				callback(nil, C3Error.questionnaireQuestionTypeUnknownToResearchKit(self))
			}
		}
		else {
			NSLog("Question «\(String(describing: text))» does not have an answer type, assuming text answer [linkId: \(link)]")
			callback(ORKAnswerFormat.textAnswerFormat(), nil)
		}
	}
	
	/**
	For `choice` type questions, retrieves the possible answers and returns them as ORKTextChoice in the callback.
	
	The `value` property of the text choice is a combination of the coding system URL and the code, separated by
	`kORKTextChoiceSystemSeparator` (a space). If no system URL is provided, "https://fhir.smalthealthit.org" is used.
	*/
	func c3_resolveAnswerChoices(callback: @escaping (([ORKTextChoice]?, Error?) -> Void)) {
		
		// options are defined inline
		if let _ = option {
			// TODO: implement!
			callback(nil, C3Error.notImplemented("Using `option` in Questionnaire.item is not yet supported, use `options`"))
		}
		
		// options are a referenced ValueSet
		else if let options = options {
			options.resolve(ValueSet.self) { valueSet in
				var choices = [ORKTextChoice]()
				
				// we have an expanded ValueSet
				if let expansion = valueSet?.expansion?.contains {
					for option in expansion {
						let system = option.system?.absoluteString ?? kORKTextChoiceDefaultSystem
						let code = option.code?.string ?? kORKTextChoiceMissingCodeCode
						let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
						let text = ORKTextChoice(text: option.display_localized ?? code, value: value as NSCoding & NSCopying & NSObjectProtocol)
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
									let code = concept.code?.string ?? kORKTextChoiceMissingCodeCode	// code is a required property, so SHOULD always be present
									let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
									let text = ORKTextChoice(text: concept.display_localized ?? code, value: value as NSCoding & NSCopying & NSObjectProtocol)
									choices.append(text)
								}
							}
						}
					}
					// TODO: also support `import`
				}
				
				// all done
				if choices.count > 0 {
					callback(choices, nil)
				}
				else {
					callback(nil, C3Error.questionnaireNoChoicesInChoiceQuestion(self))
				}
			}
		}
		else {
			callback(nil, C3Error.questionnaireNoChoicesInChoiceQuestion(self))
		}
	}
	
	/**
	For `choice` type questions, inspect if the given question is single or multiple choice. Questions are multiple choice if "repeats" is
	true and the "max-occurs" extension is either not defined or larger than 1.
	*/
	func c3_answerChoiceStyle() -> ORKChoiceAnswerStyle {
		let multiple = (repeats?.bool ?? false) && ((c3_questionMaxOccurs() ?? 2) > 1)
		return multiple ? .multipleChoice : .singleChoice
	}
}

