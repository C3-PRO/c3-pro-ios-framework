//
//  QuestionnaireController.swift
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
import ResearchKit
import SMART


/**
Instances of this class can prepare questionnaires and get a callback when preparation has finished.

Use `prepareQuestionnaireViewController()`, which fulfills any questionnaire dependencies before calling the callback, in which you get a
handle to a `ORKTaskViewController` view controller that you can present on the UI.

The `whenCompleted` callback is called when the user completes the questionnaire without cancelling nor error and provides the responses in
a `QuestionnaireResponse` resource.
The `whenCancelledOrFailed` callback is called when the questionnaire is cancelled (error = nil) or finishes with an error.

See [Questionnaire/README.md](./README.md) for detailed instructions.
*/
public class QuestionnaireController: NSObject, ORKTaskViewControllerDelegate {
	
	/// The questionnaire the controller represents.
	public final var questionnaire: Questionnaire?
	
	/// Callback called when the user finishes the questionnaire without error.
	public final var whenCompleted: ((viewController: ORKTaskViewController, answers: QuestionnaireResponse?) -> Void)?
	
	/// Callback to be called when the questionnaire is cancelled (error = nil) or finishes with an error.
	public final var whenCancelledOrFailed: ((viewController: ORKTaskViewController, error: ErrorType?) -> Void)?
	
	
	/**
	Designated initializer.
	
	- parameter questionnaire: The `Questionnaire` the receiver should handle
	*/
	public init(questionnaire: Questionnaire) {
		self.questionnaire = questionnaire
	}
	
	
	// MARK: - Questionnaire
	
	/**
	Attempts to fulfill the promise, calling the callback when done, either with a task representing the questionnaire or an error.
	
	- parameter callback: The callback once preparation has concluded, either with an ORKTask or an error. Called on the main queue.
	*/
	func prepareQuestionnaire(callback: ((task: ORKTask?, error: ErrorType?) -> Void)) {
		if let questionnaire = questionnaire {
			let promise = QuestionnairePromise(questionnaire: questionnaire)
			promise.fulfill(nil) { errors in
				dispatch_async(dispatch_get_main_queue()) {
					var multiErrors: ErrorType?
					if let errs = errors {
						multiErrors = C3Error.MultipleErrors(errs)
					}
					
					if let tsk = promise.task {
						if let errors = multiErrors {
							c3_logIfDebug("Successfully prepared questionnaire but encountered errors:\n\(errors)")
						}
						callback(task: tsk, error: multiErrors)
					}
					else {
						let err = multiErrors ?? C3Error.QuestionnaireUnknownError
						callback(task: nil, error: err)
					}
				}
			}
		}
		else {
			if NSThread.isMainThread() {
				callback(task: nil, error: C3Error.QuestionnaireNotPresent)
			}
			else {
				dispatch_async(dispatch_get_main_queue()) {
					callback(task: nil, error: C3Error.QuestionnaireNotPresent)
				}
			}
		}
	}
	
	/**
	Attempts to fulfill the promise, calling the callback when done.
	
	- parameter callback: Callback to be called on the main queue, either with a task view controller prepared for the questionnaire task or an
		error
	*/
	public func prepareQuestionnaireViewController(callback: ((viewController: ORKTaskViewController?, error: ErrorType?) -> Void)) {
		prepareQuestionnaire() { task, error in
			if let task = task {
				let viewController = ORKTaskViewController(task: task, taskRunUUID: nil)
				viewController.delegate = self
				callback(viewController: viewController, error: error)
			}
			else {
				callback(viewController: nil, error: error)
			}
		}
	}
	
	
	// MARK: - Task View Controller Delegate
	
	public func taskViewController(taskViewController: ORKTaskViewController, didFinishWithReason reason: ORKTaskViewControllerFinishReason, error: NSError?) {
		if let error = error {
			didFailWithError(taskViewController, error: error)
		}
		else {
			didFinish(taskViewController, reason: reason)
		}
	}
	
	
	// MARK: - Questionnaire Answers
	
	func didFinish(viewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason) {
		switch reason {
		case .Failed:
			didFailWithError(viewController, error: C3Error.QuestionnaireFinishedWithError)
		case .Completed:
			whenCompleted?(viewController: viewController, answers: viewController.result.c3_asQuestionnaireResponseForTask(viewController.task))
		case .Discarded:
			didFailWithError(viewController, error: nil)
		case .Saved:
			// TODO: support saving tasks
			didFailWithError(viewController, error: nil)
		}
	}
	
	func didFailWithError(viewController: ORKTaskViewController, error: ErrorType?) {
		whenCancelledOrFailed?(viewController: viewController, error: error)
	}
}

