//
//  QuestionnaireController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 5/20/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import ResearchKit
import SMART

let CHIPQuestionnaireErrorKey = "CHIPQuestionnaireError"


/**
    Instances of this class can prepare questionnaires and get a callback when it's finished.
 */
public class QuestionnaireController: NSObject, ORKTaskViewControllerDelegate
{
	public final var questionnaire: Questionnaire?
	
	/// Callback called when the user finishes the questionnaire without error.
	public final var whenCompleted: ((answers: QuestionnaireAnswers?) -> Void)?
	
	/// Callback to be called when the questionnaire is cancelled (error = nil) or finishes with an error.
	public final var whenCancelledOrFailed: ((error: NSError?) -> Void)?
	
	
	// MARK: - Questionnaire
	
	/**
	Attempts to fulfill the promise, calling the callback when done, either with a task representing the questionnaire or an error.
	
	:param callback: The callback once preparation has concluded, either with an ORKTask or an error. Called on the main queue.
	*/
	func prepareQuestionnaire(callback: ((task: ORKTask?, error: NSError?) -> Void)) {
		if let questionnaire = questionnaire {
			let promise = QuestionnairePromise(questionnaire: questionnaire)
			promise.fulfill(nil) { errors in
				dispatch_async(dispatch_get_main_queue()) {
					var multiErrors: NSError?
					if let errs = errors {
						if 1 == errs.count {
							multiErrors = errs[0]
						}
						else {
							multiErrors = chip_genErrorQuestionnaire(errs.map() { $0.localizedDescription }.reduce("") { $0 + (!$0.isEmpty ? "\n" : "") + $1 })
						}
					}
					
					if let tsk = promise.task {
						if let errors = multiErrors {
							chip_logIfDebug("Successfully prepared questionnaire but encountered errors:\n\(errors.localizedDescription)")
						}
						callback(task: tsk, error: multiErrors)
					}
					else {
						let err = multiErrors ?? chip_genErrorQuestionnaire("Unknown error creating a task from questionnaire")
						callback(task: nil, error: err)
					}
				}
			}
		}
		else {
			let err = chip_genErrorQuestionnaire("I do not have a questionnaire just yet, cannot start")
			if NSThread.isMainThread() {
				callback(task: nil, error: err)
			}
			else {
				dispatch_async(dispatch_get_main_queue()) {
					callback(task: nil, error: err)
				}
			}
		}
	}
	
	/**
	Attempts to fulfill the promise, calling the callback when done.
	
	:param callback: Callback to be called on the main queue, either with a task view controller prepared for the questionnaire task or an
		error
	*/
	public func prepareQuestionnaireViewController(callback: ((viewController: ORKTaskViewController?, error: NSError?) -> Void)) {
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
			didFailWithError(error)
		}
		else {
			didFinish(taskViewController, reason: reason)
		}
	}
	
	
	// MARK: - Questionnaire Answers
	
	func didFinish(viewController: ORKTaskViewController, reason: ORKTaskViewControllerFinishReason) {
		switch reason {
		case .Failed:
			didFailWithError(chip_genErrorQuestionnaire("unknown error finishing questionnaire"))
		case .Completed:
			whenCompleted?(answers: viewController.result.chip_asQuestionnaireAnswersForTask(viewController.task))
		case .Discarded:
			didFailWithError(nil)
		case .Saved:
			// TODO: support saving tasks
			didFailWithError(nil)
		}
	}
	
	func didFailWithError(error: NSError?) {
		whenCancelledOrFailed?(error: error)
	}
}


/**
    Convenience function to create an NSError in our questionnaire error domain.
 */
public func chip_genErrorQuestionnaire(message: String, code: Int = 0) -> NSError {
	return NSError(domain: CHIPQuestionnaireErrorKey, code: code, userInfo: [NSLocalizedDescriptionKey: message])
}

