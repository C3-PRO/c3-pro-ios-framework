//
//  WebViewController.swift
//  c3-pro
//
//  Created by Pascal Pfiffner on 5/19/15.
//  Copyright (c) 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


public class WebViewController : UIViewController, UIWebViewDelegate {
	
	public internal(set) var webView: UIWebView?
	
	public var openLinksExternally = true
	
	public var startURL: NSURL?
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		view.backgroundColor = UIColor.lightGrayColor()
		edgesForExtendedLayout = .All
		
		// create webview
		let web = UIWebView()
		web.translatesAutoresizingMaskIntoConstraints = false
		web.delegate = self
		web.dataDetectorTypes = .All
		web.scrollView.decelerationRate = UIScrollViewDecelerationRateNormal;
		webView = web
		
		view.addSubview(web)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[web]|", options: [], metrics: nil, views: ["web": web]))
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[web]|", options: [], metrics: nil, views: ["web": web]))
	}
	
	override public func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if let webView = webView where nil == webView.request {
			loadStartURL()
		}
	}
	
	
	// MARK: - App Style
	
	static var _appStyle: String?
	
	var appStyle: String {
		if nil == self.dynamicType._appStyle {
			if let styleURL = NSBundle.mainBundle().URLForResource("Intro", withExtension: "css") ?? NSBundle.mainBundle().URLForResource("Intro", withExtension: "css", subdirectory: "HTMLContent") {
				self.dynamicType._appStyle = (try? NSString(contentsOfFile: styleURL.path!, encoding: NSUTF8StringEncoding)) as? String
			}
			else {
				chip_warn("Please include a CSS stylesheet called «Intro.css» in the app bundle")
			}
		}
		return self.dynamicType._appStyle ?? ""
	}
	
	public func htmlDocWithContent(content: String) -> String {
		return "<!DOCTYPE html><html><head><style>\(appStyle)</style></head><body><div style=\"padding:20px 15px;\">\(content)</div></body></html>"
	}
	
	
	// MARK: - Content
	
	public func loadStartURL() {
		if let startURL = startURL, let webView = webView {
			let request = NSURLRequest(URL: startURL)
			webView.loadRequest(request)
		}
	}
	
	
	// MARK: - Web View Delegate
	
	public func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
		if openLinksExternally && .LinkClicked == navigationType, let url = request.URL {
			UIApplication.sharedApplication().openURL(url)
			return false
		}
		return true
	}
}


public class PDFViewController : WebViewController, UIDocumentInteractionControllerDelegate {
	
	var shareButton: UIBarButtonItem?
	
	var documentInteraction: UIDocumentInteractionController?
	
	private var PDFURL: NSURL? {
		didSet {
			shareButton?.enabled = nil != PDFURL
		}
	}
	
	override public func viewDidLoad() {
		super.viewDidLoad()
		
		// create share button
		let share = UIBarButtonItem(barButtonSystemItem: .Action, target: self, action: "share")
		share.enabled = nil != PDFURL
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
	
	public func loadPDFDataFrom(url: NSURL) {
		PDFURL = url
		if let web = webView {
			let request = NSURLRequest(URL: url)
			web.loadRequest(request)
		}
	}
	
	
	// MARK: - Sharing
	
	public func share() {
		if let url = PDFURL {
			documentInteraction = UIDocumentInteractionController(URL: url)
			documentInteraction!.delegate = self;
			documentInteraction!.name = self.title;
			
			documentInteraction!.presentOptionsMenuFromBarButtonItem(shareButton!, animated: true)
		}
	}
	
	public func documentInteractionControllerDidDismissOpenInMenu(controller: UIDocumentInteractionController) {
		if documentInteraction === controller {
			documentInteraction = nil
		}
	}
}

