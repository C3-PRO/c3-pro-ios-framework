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


open class StudyIntroWelcomeCell: UICollectionViewCell {
	
	@IBOutlet open var image: UIImageView?
	
	@IBOutlet open var titleLabel: UILabel?
	
	@IBOutlet open var subtitleLabel: UILabel?
	
	@IBOutlet open var consentButton: UIButton?
	
	@IBOutlet open var videoButton: UIButton?
	
	@IBOutlet open var swipeLabel: UILabel?
	
	open var onConsentTap: ((Void) -> Void)?
	open var onVideoTap: ((_ name: String) -> Void)?
	
	open var item: StudyIntroWelcomeItem? {
		didSet {
			setupCell(with: item)
		}
	}
	
	override open func prepareForReuse() {
		super.prepareForReuse()
		titleLabel?.numberOfLines = (bounds.size.height > 280.0) ? 0 : 1;			// to force one line on iPhone 4S
	}
	
	func setupCell(with item: StudyIntroWelcomeItem?) {
		if let item = item {
			if let logo = item.logoName {
				image?.image = UIImage(named: logo)
			}
			titleLabel?.text = item.title
			subtitleLabel?.text = item.subtitle
		}
		videoButton?.isEnabled = (nil != item?.videoName)
		videoButton?.isHidden = (nil == item?.videoName)
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
			exec(video)
		}
		else {
			c3_warn("Have not assigned `onVideoTap` or the welcome item does not define `videoName`")
		}
	}
}


open class StudyIntroVideoCell: UICollectionViewCell {

	@IBOutlet open var titleLabel: UILabel?
	
	@IBOutlet open var videoButton: UIButton?
	
	@IBOutlet open var videoMessage: UILabel?
	
	open var onVideoTap: ((String) -> Void)?
	
	open var item: StudyIntroVideoItem? {
		didSet {
			setupCell(with: item)
		}
	}
	
	func setupCell(with item: StudyIntroVideoItem?) {
		if let item = item {
			videoButton?.setImage(UIImage(named: item.videoIconName), for: UIControlState())
		}
		videoButton?.isEnabled = (nil != item?.videoName)
	}
	
	@IBAction func showVideo() {
		if let exec = onVideoTap, let video = item?.videoName {
			exec(video)
		}
		else {
			c3_warn("Have not assigned `onVideoTap` or the video item does not define `videoName`")
		}
	}
}


open class StudyIntroHTMLCell: UICollectionViewCell, UIWebViewDelegate {
	
	@IBOutlet open var webView: UIWebView?
	
	open var item: StudyIntroHTMLItem? {
		didSet {
			setupCell(with: item)
		}
	}
	
	func setupCell(with item: StudyIntroHTMLItem?) {
		if let url = item?.url {
			webView?.loadRequest(URLRequest(url: url as URL))
		}
	}
	
	
	open func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if .linkClicked == navigationType, let url = request.url {
			return !UIApplication.shared.openURL(url)
		}
		return true
	}
	
	open func webViewDidFinishLoad(_ webView: UIWebView) {
		webView.stringByEvaluatingJavaScript(from: "document.documentElement.style.webkitUserSelect=\"none\"")		// disable text selection
	}
}

