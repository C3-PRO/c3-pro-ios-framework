//
//  StudyIntroCollectionViewCell.swift
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

import UIKit


public class StudyIntroWelcomeCell: UICollectionViewCell {
	
	@IBOutlet public var image: UIImageView?
	
	@IBOutlet public var titleLabel: UILabel?
	
	@IBOutlet public var subtitleLabel: UILabel?
	
	@IBOutlet public var consentButton: UIButton?
	
	@IBOutlet public var videoButton: UIButton?
	
	@IBOutlet public var swipeLabel: UILabel?
	
	public var onConsentTap: (Void -> Void)?
	public var onVideoTap: ((name: String) -> Void)?
	
	public var item: StudyIntroWelcomeItem? {
		didSet {
			setupCellWithItem(item)
		}
	}
	
	public override func prepareForReuse() {
		super.prepareForReuse()
		titleLabel?.numberOfLines = (bounds.size.height > 280.0) ? 0 : 1;			// to force one line on iPhone 4S
	}
	
	func setupCellWithItem(item: StudyIntroWelcomeItem?) {
		if let item = item {
			if let logo = item.logoName {
				image?.image = UIImage(named: logo)
			}
			titleLabel?.text = item.title
			subtitleLabel?.text = item.subtitle
		}
		videoButton?.enabled = (nil != item?.videoName)
		videoButton?.hidden = (nil == item?.videoName)
	}
	
	
	// MARK: - Actions
	
	@IBAction func showConsent() {
		if let exec = onConsentTap {
			exec()
		}
		else {
			c3_warn("Have not yet assigned `onConsentTap`")
		}
	}
	
	@IBAction func showVideo() {
		if let exec = onVideoTap, let video = item?.videoName {
			exec(name: video)
		}
		else {
			c3_warn("Have not assigned `onVideoTap` or the welcome item does not define `videoName`")
		}
	}
}


public class StudyIntroVideoCell: UICollectionViewCell {

	@IBOutlet public var titleLabel: UILabel?
	
	@IBOutlet public var videoButton: UIButton?
	
	@IBOutlet public var videoMessage: UILabel?
	
	public var onVideoTap: ((name: String) -> Void)?
	
	public var item: StudyIntroVideoItem? {
		didSet {
			setupCellWithItem(item)
		}
	}
	
	func setupCellWithItem(item: StudyIntroVideoItem?) {
		if let item = item {
			videoButton?.setImage(UIImage(named: item.videoIconName), forState: .Normal)
		}
		videoButton?.enabled = (nil != item?.videoName)
	}
	
	@IBAction func showVideo() {
		if let exec = onVideoTap, let video = item?.videoName {
			exec(name: video)
		}
		else {
			c3_warn("Have not assigned `onVideoTap` or the video item does not define `videoName`")
		}
	}
}


public class StudyIntroHTMLCell: UICollectionViewCell, UIWebViewDelegate {
	
	@IBOutlet public var webView: UIWebView?
	
	public var item: StudyIntroHTMLItem? {
		didSet {
			setupCellWithItem(item)
		}
	}
	
	func setupCellWithItem(item: StudyIntroHTMLItem?) {
		if let url = item?.url {
			webView?.loadRequest(NSURLRequest(URL: url))
		}
	}
	
	
	public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if .LinkClicked == navigationType, let url = request.URL {
			return !UIApplication.sharedApplication().openURL(url)
		}
		return true
	}
	
	public func webViewDidFinishLoad(webView: UIWebView) {
		webView.stringByEvaluatingJavaScriptFromString("document.documentElement.style.webkitUserSelect=\"none\"")		// disable text selection
	}
}

