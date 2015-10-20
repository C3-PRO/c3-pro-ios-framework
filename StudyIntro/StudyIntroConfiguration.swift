//
//  StudyIntroConfiguration.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
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
      ]
    }

*/
public class StudyIntroConfiguration {
	
	public internal(set) var title: String?
	
	public internal(set) var logoName: String?
	
	public internal(set) var items: [StudyIntroItem]?
	
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

