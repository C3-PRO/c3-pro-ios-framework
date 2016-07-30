//
//  WebViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
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


/**
A web view controller, built on `UIWebView`, to display bundled HTML content.
*/
public class WebViewController : UIViewController, UIWebViewDelegate {
	
	/// The web view.
	public internal(set) var webView: UIWebView?
	
	/// Whether links should open in the receiver or open in Safari (default).
	public var openLinksExternally = true
	
	/// The URL to load on view instantiation.
	public var startURL: URL?
	
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.lightGray()
		edgesForExtendedLayout = .all
		
		// create webview
		let web = UIWebView()
		web.translatesAutoresizingMaskIntoConstraints = false
		web.delegate = self
		web.dataDetectorTypes = .all
		if #available(iOS 9.0, *) {
		    web.allowsLinkPreview = true
		}
		web.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
		webView = web
		
		view.addSubview(web)
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[web]|", options: [], metrics: nil, views: ["web": web]))
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[web]|", options: [], metrics: nil, views: ["web": web]))
	}
	
	override public func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let webView = webView where nil == webView.request {
			loadStartURL()
		}
	}
	
	
	// MARK: - App Style
	
	static var _appStyle: String?
	
	/// The CSS style to apply.
	var appStyle: String {
		if nil == self.dynamicType._appStyle {
			if let styleURL = Bundle.main.urlForResource("Intro", withExtension: "css") ?? Bundle.main.urlForResource("Intro", withExtension: "css", subdirectory: "HTMLContent") {
				self.dynamicType._appStyle = (try? NSString(contentsOfFile: styleURL.path!, encoding: String.Encoding.utf8.rawValue)) as? String
			}
			else {
				c3_warn("Please include a CSS stylesheet called «Intro.css» in the app bundle")
			}
		}
		return self.dynamicType._appStyle ?? ""
	}
	
	/**
	Wraps given HTML content in a full <html> document, applying `appStyle`.
	
	- parameter content: The HTML Body content, wrapped into `<body><div>...</div></body>`.
	- returns: A full HTML document string
	*/
	public func htmlDocWithContent(_ content: String) -> String {
		return "<!DOCTYPE html><html><head><style>\(appStyle)</style></head><body><div style=\"padding:20px 15px;\">\(content)</div></body></html>"
	}
	
	
	// MARK: - Content
	
	/** Make `webView` load `startURL`. */
	public func loadStartURL() {
		if let startURL = startURL, let webView = webView {
			let request = URLRequest(url: startURL)
			webView.loadRequest(request)
		}
	}
	
	
	// MARK: - Web View Delegate
	
	public func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if openLinksExternally && .linkClicked == navigationType, let url = request.url {
			UIApplication.shared().openURL(url)
			return false
		}
		return true
	}
}


/**
A PDF view controller, built on `UIWebView`, to display bundled PDF files.
*/
public class PDFViewController : WebViewController, UIDocumentInteractionControllerDelegate {
	
	var shareButton: UIBarButtonItem?
	
	var documentInteraction: UIDocumentInteractionController?
	
	private var PDFURL: URL? {
		didSet {
			shareButton?.isEnabled = nil != PDFURL
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		// create share button
		let share = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(PDFViewController.share))
		share.isEnabled = nil != PDFURL
		shareButton = share
		
		if nil == navigationItem.rightBarButtonItem {
			navigationItem.rightBarButtonItem = share
		}
		else {
			navigationItem.leftBarButtonItem = share
		}
		
		if let url = PDFURL {
			loadPDFDataFrom(url)
		}
	}
	
	/**
	Loads PDF data from the given url.
	
	- parameter url: The URL to load PDF data from
	*/
	public func loadPDFDataFrom(_ url: URL) {
		PDFURL = url
		if let web = webView {
			let request = URLRequest(url: url)
			web.loadRequest(request)
		}
	}
	
	
	// MARK: - Sharing
	
	/**
	Display a `UIDocumentInteractionController` so the user can share the PDF.
	*/
	public func share() {
		if let url = PDFURL {
			documentInteraction = UIDocumentInteractionController(url: url)
			documentInteraction!.delegate = self;
			documentInteraction!.name = self.title;
			documentInteraction!.presentOptionsMenu(from: shareButton!, animated: true)
		}
	}
	
	public func documentInteractionControllerDidDismissOpenInMenu(_ controller: UIDocumentInteractionController) {
		if documentInteraction === controller {
			documentInteraction = nil
		}
	}
}

