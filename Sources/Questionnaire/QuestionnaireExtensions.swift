//
//  QuestionnaireExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/20/15.
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


/** Extending `SMART.Element` for use with ResearchKit. */
extension Element {
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


/** Extending `SMART.Extension` for use with ResearchKit. */
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

