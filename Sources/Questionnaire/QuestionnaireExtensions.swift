//
//  QuestionnaireExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


extension FHIRElement {
	/**
	Tries to find the "enableWhen" extension on questionnaire groups and questions, and if there are any instantiates ResultRequirements
	representing those.
	*/
	func chip_enableQuestionnaireElementWhen() throws -> [ResultRequirement]? {
		if let enableWhen = extensionsFor("http://hl7.org/fhir/StructureDefinition/questionnaire-enableWhen") {
			var requirements = [ResultRequirement]()
			
			for when in enableWhen {
				let question = when.extension_fhir?.filter() { return $0.url?.fragment == "question" }.first
				let answer = when.extension_fhir?.filter() { return $0.url?.fragment == "answer" }.first
				if let answer = answer, let questionIdentifier = question?.valueString {
					let result = try answer.chip_desiredResultForValueOfStep(questionIdentifier)
					let req = ResultRequirement(step: questionIdentifier, result: result)
					requirements.append(req)
				}
				else if nil != answer {
					throw C3Error.ExtensionIncomplete("'enableWhen' extension on \(self) has no #question.valueString as identifier")
				}
				else {
					throw C3Error.ExtensionIncomplete("'enableWhen' extension on \(self) has no #answer")
				}
			}
			return requirements
		}
		return nil
	}
}


extension Extension {
	/**
	If this is an "answer" extension in questionnaire "enableWhen" extensions, returns the result that is required for the parent element to
	be shown.
	
	Throws if the extension cannot be converted to a result, you might want to be graceful catching these errors
	
	- parameter stepIdentifier: The identifier of the step this extension applies to
	- returns: An ORKQuestionResult representing the result that is required for the Group or Question to be shown
	*/
	func chip_desiredResultForValueOfStep(stepIdentifier: String) throws -> ORKQuestionResult {
		if "answer" != url?.fragment {
			throw C3Error.ExtensionInvalidInContext
		}
		
		// standard bool switch
		if let flag = valueBoolean {
			let result = ORKBooleanQuestionResult(identifier: stepIdentifier)
			result.answer = flag
			return result
		}
		
		// "Coding" value, which should be represented as a choice question
		if let val = valueCoding {
			if let code = val.code {
				let result = ORKChoiceQuestionResult(identifier: stepIdentifier)
				let system = val.system?.absoluteString ?? kORKTextChoiceDefaultSystem
				let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
				result.answer = [value]
				return result
			}
			throw C3Error.ExtensionIncomplete("Extension has `valueCoding` but is missing a code, cannot create an answer")
		}
		throw C3Error.NotImplemented("create question results from value types other than bool and codeable concept, skipping \(url)")
	}
}

