//
//  CHIPExtensions.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 4/27/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


extension FHIRElement
{
	/** Tries to find the "enableWhen" extension on questionnaire groups and questions, and if there are any
		instantiates ResultRequirements representing those.
	 */
	func chip_enableQuestionnaireElementWhen(error: NSErrorPointer) -> [ResultRequirement]? {
		let optWhen = extension_fhir?.filter() { return $0.url?.absoluteString == "http://hl7.org/fhir/StructureDefinition/questionnaire-enableWhen" }
		if let enableWhen = optWhen {
			var requirements = [ResultRequirement]()
			
			for when in enableWhen {
				let question = when.extension_fhir?.filter() { return $0.url?.fragment == "question" }.first
				let answer = when.extension_fhir?.filter() { return $0.url?.fragment == "answer" }.first
				if let questionIdentifier = question?.valueString {
					if let result = answer?.chip_desiredResultForValueOfStep(questionIdentifier, error: error) {
						let req = ResultRequirement(step: questionIdentifier, result: result)
						requirements.append(req)
					}
					else {
						//return nil		// let us be graceful during development period not fail on errors
					}
				}
				else {
					chip_logIfDebug("Found 'enableWhen' extension on \(self), but there is no question identifier")
				}
			}
			return requirements.isEmpty ? nil : requirements
		}
		return nil
	}
}


extension Extension
{
	/** If this is an "answer" extension in questionnaire "enableWhen" extensions, returns the result that is required
		for the parent element to be shown.
		
		:returns: An ORKQuestionResult representing the result that is required for the Group or Question to be shown
	 */
	func chip_desiredResultForValueOfStep(stepIdentifier: String, error: NSErrorPointer) -> ORKQuestionResult? {
		if "answer" != url?.fragment {
			return nil
		}
		
		// "Coding" value, which should be represented as a choice question
		if let val = valueCoding {
			if let code = val.code {
				let result = ORKChoiceQuestionResult(identifier: stepIdentifier)
				result.answer = [code]
				return result
			}
			else {
				let err = createQuestionnaireError("Extension has `valueCoding` but is missing a code, cannot create an answer")
				chip_logIfDebug(err.localizedDescription)
				if nil != error {
					error.memory = err
				}
			}
		}
		else {
			chip_logIfDebug("Have yet to implement all value types to create question results from, skipping \(url)")
		}
		return nil
	}
}


extension String
{
	func chip_stripMultipleSpaces() -> String {
		if let regEx = NSRegularExpression(pattern: " +", options: nil, error: nil) {
			return regEx.stringByReplacingMatchesInString(self, options: nil, range: NSMakeRange(0, count(self)), withTemplate: " ")
		}
		return self
	}
}


func chip_logIfDebug(@autoclosure message: () -> String, function: String = __FUNCTION__, file: String = __FILE__, line: Int = __LINE__) {
	#if DEBUG
	println("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}

