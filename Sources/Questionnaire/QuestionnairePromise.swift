//
//  QuestionnairePromise.swift
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


/**
Protocol for our questionnaire promise architecture.
*/
protocol QuestionnairePromiseProto: CustomStringConvertible {
	
	var steps: [ORKStep]? { get }
	
	func fulfill(requiring parentRequirements: [ResultRequirement]?, callback: @escaping (([Error]?) -> Void))
}


/**
A promise that can turn a FHIR Questionnaire into an ORKOrderedTask.
*/
open class QuestionnairePromise: QuestionnairePromiseProto {
	
	/// The promises' questionnaire.
	let questionnaire: Questionnaire
	
	/// The questionnaire's steps, internally assigned after the promise has been successfully fulfilled.
	internal(set) open var steps: [ORKStep]?
	
	/// The task representing the questionnaire; available once the promise has been fulfilled.
	internal(set) open var task: ORKTask?
	
	public init(questionnaire: Questionnaire) {
		self.questionnaire = questionnaire
	}
	
	
	// MARK: - Fulfilling
	
	/**
	Attempts to fulfill the questionnaire promise by creating steps for all questions.
	
	Upon completion, the receiver has filled its `steps` and `task` properties for you to use; unless there was an error preventing creation
	of those. Errors may be reported but steps and the task may still be created.
	
	- parameter parentRequirements: An array of ResultRequirement instances required by parent elements
	- parameter callback: Callback to be called upon promise fulfillment with a list of errors, if any. Called on the main thread.
	*/
	open func fulfill(requiring parentRequirements: [ResultRequirement]?, callback: @escaping (([Error]?) -> Void)) {
		if let toplevel = questionnaire.group {
			let identifier = questionnaire.id ?? (questionnaire.identifier?.first?.value ?? "questionnaire-task")
			let gpromise = QuestionnaireGroupPromise(group: toplevel)
			gpromise.fulfill(requiring: parentRequirements) { errors in
				if let steps = gpromise.steps {
				self.steps = steps
				self.task = ConditionalOrderedTask(identifier: identifier, steps: steps)
					callback(errors)
				}
				else {
					callback(errors ?? [C3Error.questionnaireUnknownError])
				}
			}
		}
		else {
			callback([C3Error.questionnaireInvalidNoTopLevelItem])
		}
	}
	
	
	// MARK: - Printable
	
	/// String representation of the receiver.
	open var description: String {
		return "<\(type(of: self))>"
	}
}

