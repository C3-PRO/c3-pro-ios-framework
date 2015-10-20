//
//  StudyIntroItem.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//


public protocol StudyIntroItem {
	
	static var cellReuseIdentifier: String { get }
}


public class StudyIntroWelcomeItem: StudyIntroItem {
	
	public static var cellReuseIdentifier = "WelcomeCell"
	
	public var logoName: String? = "logo_disease_large"
	
	public var title: String?
	
	public var subtitle: String?
	
	public var videoName: String?
	
	public var swipeText = NSLocalizedString("Swipe to learn more", comment: "")
	
	public init(title: String, subtitle: String, video: String) {
		self.title = title
		self.subtitle = subtitle
		self.videoName = video
	}
}


public class StudyIntroVideoItem: StudyIntroItem {
	
	public static var cellReuseIdentifier = "VideoCell"
	
	public var videoIconName: String = "video_icon"
	
	public var videoName: String?
	
	public init(video: String) {
		videoName = video
	}
}


public class StudyIntroHTMLItem: StudyIntroItem {

	public static var cellReuseIdentifier = "WebCell"
	
	public var title: String?
	
	public var filename: String?
	
	var url: NSURL? {
		if let filename = filename {
			let url = NSBundle.mainBundle().URLForResource(filename, withExtension: "html") ?? NSBundle.mainBundle().URLForResource(filename, withExtension: "html", subdirectory: "HTMLContent")
			if nil == url {
				fatalError("Expecting file «\(filename).html» to be present in the bundle (or its «HTMLContent» directory), but didn't find it")
			}
			return url
		}
		return nil
	}
	
	public init(title: String, filename: String) {
		self.title = title
		self.filename = filename
	}
}

