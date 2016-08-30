//
//  StudyIntroItem.swift
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
Study intro items represent one section to be shown on the introduction screen. Future participants can swipe between intro items to learn
more about the study.

Typically, each concrete study item is represented by a different type of collection view cell, hence the static `cellReuseIdentifier`
property.
*/
public protocol StudyIntroItem {
	
	/// The cell reuse identifier to be used for items.
	static var cellReuseIdentifier: String { get }
}


/**
Represents an intro item that shows the familiar "Welcome" screen.
*/
open class StudyIntroWelcomeItem: StudyIntroItem {
	
	open static var cellReuseIdentifier = "WelcomeCell"
	
	/// The name of the image to be shown, square, above the title. Defaults to "logo_disease_large".
	open var logoName: String? = "logo_disease_large"
	
	/// The main title of your study/app.
	open var title: String?
	
	/// A short subtitle.
	open var subtitle: String?
	
	/// If set to a filename (without `.mp4`), a "Show Video" button will show up.
	open var videoName: String?
	
	/// Text at the bottom, informing the user about the possibility to swipe contents
	open var swipeText = "Swipe to learn more".c3_localized
	
	public init(title: String, subtitle: String?, video: String?) {
		self.title = title
		self.subtitle = subtitle
		self.videoName = video
	}
}


/**
An intro item that only shows a title and a large thumbnail, representing the movie.
*/
open class StudyIntroVideoItem: StudyIntroItem {
	
	open static var cellReuseIdentifier = "VideoCell"
	
	/// The image name to be shown on the button. Defaults to "video_icon".
	open var videoIconName: String = "video_icon"
	
	/// The name of the video file, without the `.mp4` extension.
	open var videoName: String?
	
	public init(video: String) {
		videoName = video
	}
}


/**
An intro item that will render an HTML page; only accepts HTML files that are included in the app bundle.
*/
open class StudyIntroHTMLItem: StudyIntroItem {

	open static var cellReuseIdentifier = "WebCell"
	
	/// The item's title.
	open var title: String?
	
	/// The name of the file included in the bundle, either at the top level or in a `HTMLContent` subdirectory.
	open var filename: String?
	
	var url: URL? {
		if let filename = filename {
			let url = Bundle.main.url(forResource: filename, withExtension: "html") ?? Bundle.main.url(forResource: filename, withExtension: "html", subdirectory: "HTMLContent")
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

