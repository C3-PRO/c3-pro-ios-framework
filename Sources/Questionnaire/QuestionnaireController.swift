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

See [Questionnaire/README.md](https://github.com/C3-PRO/c3-pro-ios-framework/tree/master/Sources/Questionnaire#questionnairecontroller) for detailed instructions.
*/
open class QuestionnaireController: NSObject, ORKTaskViewControllerDelegate {
	
	/// The questionnaire the controller represents.
	public final var questionnaire: Questionnaire?
	
	/// Callback called when the user finishes the questionnaire without error.
	public final var whenCompleted: ((_ viewController: ORKTaskViewController, _ answers: QuestionnaireResponse?) -> Void)?
	
	/// Callback to be called when the questionnaire is cancelled (Error = nil) or finishes with an error.
	public final var whenCancelledOrFailed: ((ORKTaskViewController, Error?) -> Void)?
	
	/// The logger to use, if any.
	open var logger: OAuth2Logger?
	
	
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
	func prepareQuestionnaire(callback: @escaping ((ORKTask?, Error?) -> Void)) {
		if let questionnaire = questionnaire {
			logger?.trace("C3-PRO", msg: "Fulfilling promise for \(questionnaire)")
			let promise = QuestionnairePromise(questionnaire: questionnaire)
			promise.fulfill(requiring: nil) { errors in
				DispatchQueue.main.async {
					var multiErrors: Error?
					if let errs = errors {
						multiErrors = C3Error.multipleErrors(errs)
					}
					
					if let tsk = promise.task {
						if let errors = multiErrors {
							self.logger?.debug("C3-PRO", msg: "Successfully prepared questionnaire but encountered errors:\n\(errors)")
						}
						self.logger?.trace("C3-PRO", msg: "Promise for \(questionnaire) fulfilled")
						callback(tsk, multiErrors)
					}
					else {
						let err = multiErrors ?? C3Error.questionnaireUnknownError
						self.logger?.trace("C3-PRO", msg: "Promise for \(questionnaire) fulfilled with error \(err)")
						callback(nil, err)
					}
				}
			}
		}
		else {
			callOnMainThread {
				callback(nil, C3Error.questionnaireNotPresent)
			}
		}
	}
	
	/**
	Attempts to fulfill the promise, calling the callback when done.
	
	- parameter callback: Callback to be called on the main queue, either with a task view controller prepared for the questionnaire task or an
		error
	*/
	open func prepareQuestionnaireViewController(callback: @escaping ((ORKTaskViewController?, Error?) -> Void)) {
		prepareQuestionnaire() { task, error in
			if let task = task {
				let viewController = ORKTaskViewController(task: task, taskRun: nil)
				viewController.delegate = self
				callback(viewController, error)
			}
			else {
				callback(nil, error)
			}
		}
	}
	
	
	// MARK: - Task View Controller Delegate
	
	open func taskViewController(_ taskViewController: ORKTaskViewController, didFinishWith reason: ORKTaskViewControllerFinishReason, error: Error?) {
		if let error = error {
			didFailWithError(taskViewController, error: error)
		}
		else {
			didFinish(taskViewController, reason: reason)
		}
	}
	
	
	// MARK: - Questionnaire Answers
	
	func didFinish(_ viewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason) {
		switch reason {
		case .failed:
			didFailWithError(viewController, error: C3Error.questionnaireFinishedWithError)
		case .completed:
			whenCompleted?(viewController, viewController.result.c3_asQuestionnaireResponse(for: viewController.task))
		case .discarded:
			didFailWithError(viewController, error: nil)
		case .saved:
			// TODO: support saving tasks
			didFailWithError(viewController, error: nil)
		}
	}
	
	func didFailWithError(_ viewController: ORKTaskViewController, error: Error?) {
		whenCancelledOrFailed?(viewController, error)
	}
}

