//
//  ORKTaskResult+FHIR.swift
//  ResearchCHIP
//
//  Created by Pascal Pfiffner on 6/26/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import ResearchKit
import SMART


/**
    Extend ORKTaskResult to add functionality to convert to QuestionnaireAnswers.
 */
extension ORKTaskResult
{
	func asQuestionnaireAnswers() -> QuestionnaireAnswers? {
		return nil
	}
}

