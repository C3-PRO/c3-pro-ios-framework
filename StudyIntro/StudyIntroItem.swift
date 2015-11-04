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


/**
Represents an intro item that shows the familiar "Welcome" screen.
*/
public class StudyIntroWelcomeItem: StudyIntroItem {
	
	public static var cellReuseIdentifier = "WelcomeCell"
	
	/// The name of the image to be shown, square, above the title. Defaults to "logo_disease_large".
	public var logoName: String? = "logo_disease_large"
	
	/// The main title of your study/app.
	public var title: String?
	
	/// A short subtitle.
	public var subtitle: String?
	
	/// If set to a filename (without `.mp4`), a "Show Video" button will show up.
	public var videoName: String?
	
	/// Text at the bottom, informing the user about the possibility to swipe contents
	public var swipeText = NSLocalizedString("Swipe to learn more", comment: "")
	
	public init(title: String, subtitle: String?, video: String?) {
		self.title = title
		self.subtitle = subtitle
		self.videoName = video
	}
}


/**
An intro item that only shows a title and a large thumbnail, representing the movie.
*/
public class StudyIntroVideoItem: StudyIntroItem {
	
	public static var cellReuseIdentifier = "VideoCell"
	
	/// The image name to be shown on the button. Defaults to "video_icon".
	public var videoIconName: String = "video_icon"
	
	/// The name of the video file, without the `.mp4` extension.
	public var videoName: String?
	
	public init(video: String) {
		videoName = video
	}
}


/**
An intro item that will render an HTML page; only accepts HTML files that are included in the app bundle.
*/
public class StudyIntroHTMLItem: StudyIntroItem {

	public static var cellReuseIdentifier = "WebCell"
	
	public var title: String?
	
	/// The name of the file included in the bundle, either at the top level or in a `HTMLContent` subdirectory.
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

