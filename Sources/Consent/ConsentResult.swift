//
//  ConsentResult.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 04/11/15.
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

import ResearchKit


/**
Class to hold on to the consent result.
*/
open class ConsentResult {
	
	/// When the participant did consent, if at all.
	open var consentDate: Date?
	
	/// Given name of the participant.
	open var participantGivenName: String?
	
	/// Family name of the participant.
	open var participantFamilyName: String?
	
	/// Name composed of given and family name.
	open var participantFriendlyName: String? {
		if let given = participantGivenName {
			if let family = participantFamilyName {
				return "\(given) \(family)"
			}
			return given
		}
		return participantFamilyName
	}
	
	/// Image of the participant's signature.
	open var signatureImage: UIImage?
	
	/// Answer to data sharing: nil if not asked/answered, true if data may be shared widely, false if data is for study researchers only.
	open var shareWidely: Bool?
	
	
	public init(signature: ORKConsentSignature?) {
		consentDate = Date()
		participantGivenName = signature?.givenName
		participantFamilyName = signature?.familyName
		signatureImage = signature?.signatureImage
	}
}

