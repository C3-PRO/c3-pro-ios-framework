//
//  C3Error.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import Foundation
import SMART


/**
Errors thrown around when working with C3-PRO.
*/
public enum C3Error: ErrorType, CustomStringConvertible {
	case NotImplemented(String)
	case MultipleErrors(Array<ErrorType>)
	
	case AppLibraryDirectoryNotPresent
	case AppReceiptRefreshFailed
	
	case BundleFileNotFound(String)
	case InvalidJSON(String)
	case InvalidStoryboard(String)
	
	case ExtensionInvalidInContext
	case ExtensionIncomplete(String)
	
	case ConsentNoPatientReference(ErrorType)
	case ConsentContractNotPresent
	case ConsentContractHasNoTerms
	case ConsentSectionHasNoType
	case ConsentSectionTypeUnknownToResearchKit(String)
	
	case DataQueueFlushHalted
	
	case EncryptionFailedWithStatus(OSStatus)
	case EncryptionX509CertificateNotFound(String)
	case EncryptionX509CertificateNotRead(String)
	case EncryptionX509CertificateNotLoaded(String)
	
	case LocationServicesDisabled
	
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
		
		case .AppLibraryDirectoryNotPresent:
			return "The app library directory could not be found; this is likely fatal"
		case .AppReceiptRefreshFailed:
			return "App receipt refresh failed. Are you running on device?"
		
		case .BundleFileNotFound(let name):
			return name
		case .InvalidJSON(let reason):
			return "Invalid JSON: \(reason)"
		case .InvalidStoryboard(let reason):
			return "Invalid Storyboard: \(reason)"
		
		case .ExtensionInvalidInContext:
			return "This extension is not valid in this context"
		case .ExtensionIncomplete(let reason):
			return "Extension is incomplete: \(reason)"
		
		case .ConsentNoPatientReference(let underlying):
			return "Failed to generate a relative reference for the patient: \(underlying)"
		case .ConsentContractNotPresent:
			return "No Contract resource, cannot continue"
		case .ConsentContractHasNoTerms:
			return "The Contract resource does not have any terms that can be used for consenting"
		case .ConsentSectionHasNoType:
			return "Looking for consent type in ContractTerm.type.coding but none was found"
		case .ConsentSectionTypeUnknownToResearchKit(let type):
			return "Unknown consent section type “\(type)”"
		
		case .DataQueueFlushHalted:
			return "Flush halted"
		
		case .EncryptionFailedWithStatus(let status):
			return "Failed to encrypt data with key: OSStatus \(status)"
		case .EncryptionX509CertificateNotFound(let file):
			return "Bundled X509 certificate «\(file).crt» not found"
		case .EncryptionX509CertificateNotRead(let file):
			return "Failed to read bundled X509 certificate «\(file).crt»"
		case .EncryptionX509CertificateNotLoaded(let message):
			return message
		
		case .LocationServicesDisabled:
			return "Location services are disabled or have been restricted"
		
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
