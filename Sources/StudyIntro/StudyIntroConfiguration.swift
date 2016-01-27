//
//  StudyIntroConfiguration.swift
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


/**
Intro configuration can be stored to a JSON file and be read by an instance from this class.

A sample configuration, showing a `StudyIntroWelcomeItem`, a `StudyIntroVideoItem` and a `StudyIntroHTMLItem`, might look like this:

    {
      "title": "C Tracker",
      "logo": "logo_institute",
      "items": [
        {
          "type": "welcome",
          "title": "Welcome to C\u00a0Tracker",
          "subtitle": "A Hepatitis C Research Study",
          "video": "CTracker"
        },
        {
          "type": "video",
          "video": "CTracker"
        },
        {
          "title": "About this Study",
          "filename": "Intro_about",
        }
      ],
      "eligibility": {
        "letsCheckMessage": "Let's see if you're eligible to join this study",
        "eligibleMessage": "Tap the button below to start the consenting process",
        "ineligibleMessage": "Thank you for your interest"
      }
    }

*/
public class StudyIntroConfiguration {
	
	public internal(set) var title: String?
	
	public internal(set) var logoName: String?
	
	public internal(set) var items: [StudyIntroItem]?
	
	public internal(set) var eligibleLetsCheckMessage: String?
	
	public internal(set) var eligibleTitle: String?
	
	public internal(set) var eligibleMessage: String?
	
	public internal(set) var ineligibleMessage: String?
	
	public init(json filename: String, inBundle: NSBundle? = nil) throws {
		if let url = (inBundle ?? NSBundle.mainBundle()).URLForResource(filename, withExtension: "json"), let data = NSData(contentsOfURL: url) {
			let json = try NSJSONSerialization.JSONObjectWithData(data, options: [])
			
			// top level
			if let ttl = json["title"] as? String {
				title = ttl
			}
			if let logo = json["logo"] as? String {
				logoName = logo
			}
			
			// eligibility
			if let eligibility = json["eligibility"] as? [String: String] {
				if let text = eligibility["letsCheckMessage"] {
					eligibleLetsCheckMessage = text
				}
				if let text = eligibility["eligibleTitle"] {
					eligibleTitle = text
				}
				if let text = eligibility["eligibleMessage"] {
					eligibleMessage = text
				}
				if let text = eligibility["ineligibleMessage"] {
					ineligibleMessage = text
				}
			}
			
			// items
			if let items = json["items"] as? [[String: String]] {
				self.items = [StudyIntroItem]()
				for item in items {
					let type = item["type"] ?? "web"
					var intro: StudyIntroItem? = nil
					switch type {
					case "welcome":
						intro = StudyIntroWelcomeItem(title: item["title"] ?? "", subtitle: item["subtitle"], video: item["video"])
					case "video":
						intro = StudyIntroVideoItem(video: item["video"] ?? "")
					default:
						intro = StudyIntroHTMLItem(title: item["title"] ?? "", filename: item["filename"] ?? "")
					}
					
					self.items?.append(intro!)
				}
			}
			else {
				throw C3Error.InvalidJSON("No “items” array of dictionaries found")
			}
		}
		else {
			throw C3Error.BundleFileNotFound(filename)
		}
	}
}

