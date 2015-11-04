//
//  ConsentResult.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 04/11/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import ResearchKit


/**
Class to hold on to the consent result.
*/
public class ConsentResult {
	
	/// When the participant did consent, if at all.
	public var consentDate: NSDate?
	
	/// Given name of the participant.
	public var participantGivenName: String?
	
	/// Family name of the participant.
	public var participantFamilyName: String?
	
	/// Name composed of given and family name.
	public var participantFriendlyName: String? {
		if let given = participantGivenName {
			if let family = participantFamilyName {
				return "\(given) \(family)"
			}
			return given
		}
		return participantFamilyName
	}
	
	/// Image of the participant's signature.
	public var signatureImage: UIImage?
	
	/// Answer to data sharing: nil if not asked/answered, true if data may be shared widely, false if data is for study researchers only.
	public var shareWidely: Bool?
	
	
	public init(signature: ORKConsentSignature) {
		consentDate = NSDate()
		participantGivenName = signature.givenName
		participantFamilyName = signature.familyName
		signatureImage = signature.signatureImage
	}
}

