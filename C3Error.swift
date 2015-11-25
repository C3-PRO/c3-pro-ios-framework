//
//  C3Error.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import SMART


/**
Errors thrown around when working with C3-PRO.
*/
public enum C3Error: ErrorType, CustomStringConvertible {
	case NotImplemented(String)
	case MultipleErrors(Array<ErrorType>)
	
	case BundleFileNotFound(String)
	case InvalidJSON(String)
	case InvalidStoryboard(String)
	
	case ExtensionMissing(String)
	case ExtensionInvalidInContext
	case ExtensionIncomplete(String)
	
	case QuestionnaireNotPresent
	case QuestionnaireInvalidNoTopLevel
	case QuestionnaireQuestionTypeUnknownToResearchKit(QuestionnaireGroupQuestion)
	case QuestionnaireNoChoicesInChoiceQuestion(QuestionnaireGroupQuestion)
	case QuestionnaireFinishedWithError
	case QuestionnaireUnknownError
	
	/// A string representation of the error.
	public var description: String {
		switch self {
		case .NotImplemented(let message):
			return "Not yet implemented: \(message)"
		case .MultipleErrors(let errs):
			if 1 == errs.count {
				return "\(errs[0])"
			}
			let summaries = errs.map() { "\($0)" }.reduce("") { $0 + (!$0.isEmpty ? "\n" : "") + $1 }
			return "Multiple errors occurred:\n\(summaries)"
		
		case .BundleFileNotFound(let name):
			return name
		case .InvalidJSON(let reason):
			return "Invalid JSON: \(reason)"
		case .InvalidStoryboard(let reason):
			return "Invalid Storyboard: \(reason)"
		
		case .ExtensionMissing(let urlstr):
			return "Extension not present: \(urlstr)"
		case .ExtensionInvalidInContext:
			return "This extension is not valid in this context"
		case .ExtensionIncomplete(let reason):
			return "This extension is incomplete: \(reason)"
		
		case .QuestionnaireNotPresent:
			return "I do not have a questionnaire just yet"
		case .QuestionnaireInvalidNoTopLevel:
			return "Invalid questionnaire, does not contain a top level group item"
		case .QuestionnaireQuestionTypeUnknownToResearchKit(let question):
			return "Failed to map question type “\(question.type ?? "<nil>")” to ResearchKit answer format [linkId: \(question.linkId ?? "<nil>")]"
		case .QuestionnaireNoChoicesInChoiceQuestion(let question):
			return "There are no choices in question “\(question.text ?? "")” [linkId: \(question.linkId ?? "<nil>")]"
		case .QuestionnaireFinishedWithError:
			return "Unknown error finishing questionnaire"
		case .QuestionnaireUnknownError:
			return "Unknown error handling questionnaire"
		}
	}
}
