//
//  StudyIntroCollectionViewController.swift
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
import MediaPlayer


/**
A collection view controller that renders a logo image and a title at the top, a square-ish section of horizontally swipeable content in the
center, and a "Join Study" button at the bottom.

You can use `StudyIntro.storyboard` provided with the framework but **you must** add it to your app yourself. Customization is done via
configuration, which you can either do manually in code or -- much better -- by using a JSON file loaded by the `StudyIntroConfiguration`
class.
*/
public class StudyIntroCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
	
	@IBOutlet var collectionView: UICollectionView?
	@IBOutlet var topImage: UIImageView?
	@IBOutlet var topTitleLabel: UILabel?
	
	@IBOutlet var pageControl: UIPageControl?
	@IBOutlet var joinButton: UIButton?
	
	/// The title shown at the top.
	public var topTitle: String? {
		didSet {
			if isViewLoaded() {
				topTitleLabel?.text = topTitle
			}
		}
	}
	
	/// Name of the image file shown at the very top.
	public var topImageName = "logo_institute" {
		didSet {
			if isViewLoaded() {
				topImage?.image = UIImage(named: topImageName)
			}
		}
	}
	
	/// The configuration object to use to... configure the instance.
	public var config: StudyIntroConfiguration? {
		didSet {
			if let config = config {
				topTitle = config.title ?? topTitle
				topImageName = config.logoName ?? topImageName
				items = config.items ?? items
			}
		}
	}
	
	/// The study intro items to show
	public var items: [StudyIntroItem]? {
		didSet {
			if isViewLoaded() {
				pageControl?.numberOfPages = items?.count ?? 0
			}
		}
	}
	
	/// Block executed when the user taps the "Join Study" button. You usually want to start consenting when this is done.
	public var onJoinStudy: ((controller: StudyIntroCollectionViewController) -> Void)?
	
	/// If set to true (the default) will hide any navigation bar when the receiver is the top view controller
	public var hidesNavigationBar = true
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	/**
	Load the instance from the given storyboard. This is the preferred way to instantiate the intro view controller.
	*/
	public class func fromStoryboard(_ storyboardName: String) throws -> StudyIntroCollectionViewController {
		let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
		let vc = storyboard.instantiateInitialViewController()
		if let vc = vc as? StudyIntroCollectionViewController {
			return vc
		}
		throw C3Error.invalidStoryboard("The initial view controller of «\(storyboardName).storyboard» must be a `StudyIntroCollectionViewController` instance, but is: \(vc)")
	}
	
	
	// MARK: - Actions
	
	@IBAction public func joinStudy() {
		if let exec = onJoinStudy {
			exec(controller: self)
		}
		else {
			c3_warn("Tapped “Join Study” but `onJoinStudy` is not defined")
		}
	}
	
	@IBAction public func switchPage() {
		if let current = pageControl?.currentPage, let frame = collectionView?.frame {
			let offset = frame.size.width * CGFloat(current)
			collectionView?.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
		}
	}
	
	public func showConsent() {
		let pdfVC = PDFViewController()
		if let url = self.dynamicType.bundledConsentPDFURL() {
			pdfVC.title = "Consent".c3_localized
			pdfVC.hidesBottomBarWhenPushed = true
			if let navi = navigationController {
				navi.pushViewController(pdfVC, animated: true)
			}
			else {
				c3_warn("hint: if you put the intro collection view controller into a navigation controller, the consent document will be pushed instead of shown modally")
				let navi = UINavigationController(rootViewController: pdfVC)
				let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(StudyIntroCollectionViewController.dismissModal))
				pdfVC.navigationItem.rightBarButtonItem = done
				present(navi, animated: true, completion: nil)
			}
			
			DispatchQueue.main.async {
				pdfVC.loadPDFDataFrom(url)
			}
		}
		else {
			c3_warn("failed to locate consent PDF")
		}
	}
	
	public func showVideo(_ name: String) {
		if let url = Bundle.main.urlForResource(name, withExtension: "mp4") {
			let player = MPMoviePlayerViewController(contentURL: url)
			player?.moviePlayer.controlStyle = .fullscreen
			
			present(player!, animated: true, completion: nil)
		}
		else {
			c3_warn("Video named «\(name).mp4» not found in app bundle")
		}
	}
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		topTitleLabel?.text = topTitle
		topImage?.image = UIImage(named: topImageName)
		pageControl?.numberOfPages = items?.count ?? 0
	}
	
	public override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		if let layout = collectionView?.collectionViewLayout as? UICollectionViewFlowLayout {
			if let size = collectionView?.superview?.frame.size {
				layout.itemSize = size
			}
		}
	}
	
	public override func viewWillAppear(_ animated: Bool) {
		if hidesNavigationBar {
			navigationController?.setNavigationBarHidden(true, animated: animated)
		}
		super.viewWillAppear(animated)
	}
	
	public override func viewWillDisappear(_ animated: Bool) {
		if hidesNavigationBar {
			navigationController?.setNavigationBarHidden(false, animated: animated)
		}
		super.viewWillDisappear(animated)
	}
	
	func dismissModal() {
		dismiss(animated: true, completion: nil)
	}
	
	
	// MARK: - Collection View
	
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}
	
	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items?.count ?? 0
	}
	
	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let item = items![(indexPath as NSIndexPath).row]
		
		// welcome cell
		if let item = item as? StudyIntroWelcomeItem {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.dynamicType.cellReuseIdentifier, for: indexPath) as! StudyIntroWelcomeCell
			cell.item = item
			cell.onConsentTap = {
				self.showConsent()
			}
			cell.onVideoTap = { video in
				self.showVideo(video)
			}
			return cell
		}
		
		// video cell
		if let item = item as? StudyIntroVideoItem {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: item.dynamicType.cellReuseIdentifier, for: indexPath) as! StudyIntroVideoCell
			cell.item = item
			cell.onVideoTap = { video in
				self.showVideo(video)
			}
			return cell
		}
		
		// default: html cell
		let html = item as! StudyIntroHTMLItem
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: html.dynamicType.cellReuseIdentifier, for: indexPath) as! StudyIntroHTMLCell
		cell.item = html
		return cell
	}
	
	
	// MARK: - Scroll View
	
	public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if let pageWidth = collectionView?.frame.size.width, let offset = collectionView?.contentOffset.x {
			pageControl?.currentPage = Int((offset + pageWidth / 2) / pageWidth)
		}
	}
	
	
	// MARK: - Goodies
	
	/**
	Returns the URL to the bundled blank consent PDF, by default named «Consent.pdf»
	*/
	public class func bundledConsentPDFURL() -> URL? {
		return Bundle.main.urlForResource("Consent", withExtension: "pdf")
	}
}

