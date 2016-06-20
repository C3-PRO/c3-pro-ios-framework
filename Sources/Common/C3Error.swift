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
public let C3PROFHIRVersion = "1.4.0"


/**
Errors thrown around when working with C3-PRO.
*/
public enum C3Error: ErrorType, CustomStringConvertible {
	
	/// The mentioned feature is not implemented.
	case NotImplemented(String)
	
	/// An error holding on to multiple other errors.
	case MultipleErrors(Array<ErrorType>)
	
	
	// MARK: App
	
	/// The app's /Library directory is not present.
	case AppLibraryDirectoryNotPresent
	
	/// Failed to refreish the App Store receipt.
	case AppReceiptRefreshFailed
	
	/// The respective file was not found in the app bundle.
	case BundleFileNotFound(String)
	
	/// A JSON file does not have the expected structure.
	case InvalidJSON(String)
	
	/// The layout of the storyboard is not as expected.
	case InvalidStoryboard(String)
	
	
	// MARK: FHIR
	
	/// A FHIR extension is invalid in the respective context.
	case ExtensionInvalidInContext
	
	/// A FHIR extension is incomplete.
	case ExtensionIncomplete(String)
	
	
	// MARK: Consent
	
	/// The consent is lacking a patient reference.
	case ConsentNoPatientReference(ErrorType)
	
	/// The necessary contract is not present.
	case ConsentContractNotPresent
	
	/// The Contract resource does not have any `term`s that can be used for consenting.
	case ConsentContractHasNoTerms
	
	/// No ContractTerm.type.coding was found.
	case ConsentSectionHasNoType
	
	/// The given consent section type is not known to ResearchKit.
	case ConsentSectionTypeUnknownToResearchKit(String)
	
	
	// MARK: Server
	
	/// No server is configured.
	case ServerNotConfigured
	
	/// Data queue flushing was halted.
	case DataQueueFlushHalted
	
	
	// MARK: Encryption
	
	/// The given error occurred during encryption.
	case EncryptionFailedWithStatus(OSStatus)
	
	/// The X509 certificate is not present at the given location.
	case EncryptionX509CertificateNotFound(String)
	
	/// The X509 certificate could not be read from the given location.
	case EncryptionX509CertificateNotRead(String)
	
	/// The X509 certificate could not be loaded for the given reason.
	case EncryptionX509CertificateNotLoaded(String)
	
	
	// MARK: Services
	
	/// Geolocation services are disabled or restricted.
	case LocationServicesDisabled
	
	/// Access to the microphone is disabled.
	case MicrophoneAccessDenied
	
	
	// MARK: Questionnaire
	
	/// The questionnaire is not present.
	case QuestionnaireNotPresent
	
	/// The questionnaire does not have a top level item.
	case QuestionnaireInvalidNoTopLevelItem
	
	/// The given questionnaire question type cannot be represented in ResearchKit.
	case QuestionnaireQuestionTypeUnknownToResearchKit(QuestionnaireItem)
	
	/// The given question should provide choices but there are none.
	case QuestionnaireNoChoicesInChoiceQuestion(QuestionnaireItem)
	
	/// The 'item.enableWhen' property is incomplete.
	case QuestionnaireEnableWhenIncomplete(String)
	
	/// The questionnaire finished with an error (i.e. was not completed).
	case QuestionnaireFinishedWithError
	
	/// Unknown error handling questionnaire.
	case QuestionnaireUnknownError
	
	
	// MARK: HealthKit
	
	/// Access to HealthKit was not granted.
	case HealthKitNotAvailable
	
	/// There is no HealthKit sample of the given type.
	case NoSuchHKSampleType(String)
	
	/// The respective HealthKit quantity cannot be converted to the desired unit.
	case QuantityNotCompatibleWithUnit
	
	/// The interval to query data is too small.
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
		case .QuestionnaireInvalidNoTopLevelItem:
			return "Invalid questionnaire, does not contain a top level item"
		case .QuestionnaireQuestionTypeUnknownToResearchKit(let question):
			return "Failed to map question type “\(question.type ?? "<nil>")” to ResearchKit answer format [linkId: \(question.linkId ?? "<nil>")]"
		case .QuestionnaireNoChoicesInChoiceQuestion(let question):
			return "There are no choices in question “\(question.text ?? "")” [linkId: \(question.linkId ?? "<nil>")]"
		case .QuestionnaireEnableWhenIncomplete(let reason):
			return "item.enableWhen is incomplete: \(reason)"
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
func c3_logIfDebug(@autoclosure message: () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	#if DEBUG
		print("[\(file.lastPathComponent):\(line)] \(function)  \(message())")
	#endif
}


/**
Prints the given message to stdout. Prepends filename, line number, method/function name and "WARNING:".
*/
func c3_warn(@autoclosure message: () -> String, function: String = #function, file: NSString = #file, line: Int = #line) {
	print("[\(file.lastPathComponent):\(line)] \(function)  WARNING: \(message())")
}

