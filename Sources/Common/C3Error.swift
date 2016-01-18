//
//  C3Error.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
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


/// The FHIR version used by this instance of the framework.
public let C3PROFHIRVersion = "1.0.2"


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
	
	case ServerNotConfigured
	case DataQueueFlushHalted
	
	case EncryptionFailedWithStatus(OSStatus)
	case EncryptionX509CertificateNotFound(String)
	case EncryptionX509CertificateNotRead(String)
	case EncryptionX509CertificateNotLoaded(String)
	
	case LocationServicesDisabled
	case MicrophoneAccessDenied
	
	case QuestionnaireNotPresent
	case QuestionnaireInvalidNoTopLevel
	case QuestionnaireQuestionTypeUnknownToResearchKit(QuestionnaireGroupQuestion)
	case QuestionnaireNoChoicesInChoiceQuestion(QuestionnaireGroupQuestion)
	case QuestionnaireFinishedWithError
	case QuestionnaireUnknownError
	
	case HealthKitNotAvailable
	case NoSuchHKSampleType(String)
	case QuantityNotCompatibleWithUnit
	case IntervalTooSmall
	
	
	// MARK: - Custom String Convertible
	
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
		
		case .ServerNotConfigured:
			return "No server has been configured"
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
		case .MicrophoneAccessDenied:
			return "Access to the microphone has been denied for this app"
		
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
		
		case .HealthKitNotAvailable:
			return "HealthKit is not available on your device"
		case .NoSuchHKSampleType(let typeIdentifier):
			return "There is no HKSampleType “\(typeIdentifier)”"
		case .QuantityNotCompatibleWithUnit:
			return "The unit is not compatible with this quantity"
		case .IntervalTooSmall:
			return "The interval is too small"
		}
	}
}


/**
Ensures that the given block is executed on the main queue.

- parameter block: The block to execute on the main queue.
*/
public func c3_performOnMainQueue(block: (Void -> Void)) {
	if NSThread.currentThread().isMainThread {
		block()
	}
	else {
		dispatch_async(dispatch_get_main_queue()) {
			block()
		}
	}
}


/**
Prints the given message to stdout if `DEBUG` is defined and true. Prepends filename, line number and method/function name.
*/
func chip_logIfDebug(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
	#if DEBUG
		print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}


/**
Prints the given message to stdout. Prepends filename, line number, method/function name and "WARNING:".
*/
func chip_warn(@autoclosure message: () -> String, function: String = __FUNCTION__, file: NSString = __FILE__, line: Int = __LINE__) {
	print("[\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

