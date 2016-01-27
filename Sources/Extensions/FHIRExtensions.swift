//
//  FHIRExtensions.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 7/29/15.
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

import SMART


extension FHIRElement
{
	/** Returns the extension defining the inclusive lower bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_minValue() -> [Extension]? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/minValue")
	}
	
	/** Returns the extension defining the inclusive upper bound, if any. Use with "valueInteger", "valueDecimal" or other supported type. */
	final func chip_maxValue() -> [Extension]? {
		return extensionsFor("http://hl7.org/fhir/StructureDefinition/maxValue")
	}
}

