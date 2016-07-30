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


/** Extending `SMART.QuestionnaireItem` for use with ResearchKit. */
extension QuestionnaireItem {
	
	/**
	Tries to find the "enableWhen" extension on questionnaire groups and questions, and if there are any instantiates ResultRequirements
	representing those.
	*/
	func c3_enableQuestionnaireElementWhen() throws -> [ResultRequirement]? {
		if let enableWhen = enableWhen {
			var requirements = [ResultRequirement]()
			
			for when in enableWhen {
				let questionIdentifier = try when.c3_questionIdentifier()
				let result = try when.c3_answerResult(questionIdentifier)
				let req = ResultRequirement(step: questionIdentifier, result: result)
				requirements.append(req)
			}
			return requirements
		}
		return nil
	}
}


/** Extending `SMART.QuestionnaireItemEnableWhen` for use with ResearchKit. */
extension QuestionnaireItemEnableWhen {
	
	/**
	Returns the question step identifier, throws if there is none.
	
	- returns: A String representing the step identifier the receiver applies to
	*/
	func c3_questionIdentifier() throws -> String {
		guard let questionIdentifier = question else {
			throw C3Error.questionnaireEnableWhenIncomplete("\(self) has no `question` to refer to")
		}
		return questionIdentifier
	}
	
	/**
	Returns the result that is required for the parent element to be shown.
	
	Throws if the receiver cannot be converted to a result, you might want to be graceful catching these errors. Currently supports:
	
	- answerBoolean
	- answerCoding
	
	- parameter questionIdentifier: The identifier of the question step this extension applies to
	- returns: An `ORKQuestionResult` representing the result that is required for the item to be shown
	*/
	func c3_answerResult(_ questionIdentifier: String) throws -> ORKQuestionResult {
		let questionIdentifier = try c3_questionIdentifier()
		if let answer = answerBoolean {
			let result = ORKBooleanQuestionResult(identifier: questionIdentifier)
			result.answer = answer
			return result
		}
		if let answer = answerCoding {
			if let code = answer.code {
				let result = ORKChoiceQuestionResult(identifier: questionIdentifier)
				let system = answer.system?.absoluteString ?? kORKTextChoiceDefaultSystem
				let value = "\(system)\(kORKTextChoiceSystemSeparator)\(code)"
				result.answer = [value]
				return result
			}
			throw C3Error.questionnaireEnableWhenIncomplete("\(self) has `answerCoding` but is missing a code, cannot create a question result")
		}
		throw C3Error.questionnaireEnableWhenIncomplete("\(self) has no `answerXy` type that is supported right now")
	}
}

