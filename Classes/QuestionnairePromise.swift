//
//  QuestionnairePromise.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 4/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART
import ResearchKit


let CHIPQuestionnaireErrorKey = "CHIPQuestionnaireError"


/**
	Protocol for our questionnaire promise architecture.
 */
protocol QuestionnairePromiseProto: Printable
{
	var steps: [ORKStep]? { get }
	
	func fulfill(parentRequirements: [ResultRequirement]?, callback: ((errors: [NSError]?) -> Void))
}


/**
	A promise that can turn a FHIR Questionnaire into an ORKOrderedTask.
 */
public class QuestionnairePromise: QuestionnairePromiseProto
{
	/// The promises' questionnaire.
	let questionnaire: Questionnaire
	
	/// The questionnaire's steps, internally assigned after the promise has been successfully fulfilled.
	internal(set) public var steps: [ORKStep]?
	
	/// The task representing the questionnaire; available once the promise has been fulfilled.
	internal(set) public var task: ORKTask?
	
	public init(questionnaire: Questionnaire) {
		self.questionnaire = questionnaire
	}
	
	
	// MARK: - Fulfilling
	
	/** Attempts to fulfill the questionnaire promise by creating steps for all questions.
		
		Upon completion, the receiver has filled its `steps` and `task` properties for you to use; unless there was an
		error preventing creation of those. Errors may be reported but steps and the task may still be created.
	 */
	public func fulfill(parentRequirements: [ResultRequirement]?, callback: ((errors: [NSError]?) -> Void)) {
		if let toplevel = questionnaire.group {
			let identifier = toplevel.id ?? "questionnaire-task"		// TODO: inspect `identifier`
			let gpromise = QuestionnaireGroupPromise(group: toplevel)
			gpromise.fulfill(parentRequirements) { errors in
				if let steps = gpromise.steps {
					self.steps = steps
					self.task = ConditionalOrderedTask(identifier: identifier, steps: steps)
					callback(errors: errors)
				}
				else {
					callback(errors: errors ?? [createQuestionnaireError("Unknown error fulfilling questionnaire promise")])
				}
			}
		}
		else {
			callback(errors: [createQuestionnaireError("Invalid questionnaire, does not contain a top level group item")])
		}
	}
	
	
	// MARK: - Printable
	
	public var description: String {
		return NSString(format: "<QuestionnairePromise %p>", unsafeAddressOf(self)) as String
	}
}


/** Convenience function to create an NSError in our questionnaire error domain. */
public func createQuestionnaireError(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPQuestionnaireErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

