//
//  StudyIntroCollectionViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 20/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


public class StudyIntroCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate {
	
	@IBOutlet var collectionView: UICollectionView?
	@IBOutlet var topImage: UIImageView?
	@IBOutlet var topTitle: UILabel?
	
	@IBOutlet var pageControl: UIPageControl?
	@IBOutlet var joinButton: UIButton?
	
	public var topImageName = "logo_disease_researchInstitute"
	
	/// The study intro items to show
	public var items: [StudyIntroItem]? {
		didSet {
			if isViewLoaded() {
				pageControl?.numberOfPages = items?.count ?? 0
			}
		}
	}
	
	/// Block executed when the user taps the "Join Study" button. You usually want to start consenting when this is done.
	public var onSignUp: (Void -> Void)?
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	public class func fromStoryboard(storyboardName: String) -> StudyIntroCollectionViewController? {
		let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
		let vc = storyboard.instantiateInitialViewController() as? StudyIntroCollectionViewController
		if let vc = vc {
			return vc
		}
		chip_warn("The initial view controller of the given storyboard must be a `StudyIntroCollectionViewController` instance, but is: \(vc)")
		return nil
	}
	
	
	// MARK: - Actions
	
	@IBAction public func joinStudy() {
		if let exec = onSignUp {
			exec()
		}
		else {
			chip_warn("Tapped “Join Study” but `onSignUp` is not defined")
		}
	}
	
	@IBAction public func switchPage() {
		if let current = pageControl?.currentPage, let frame = collectionView?.frame {
			let offset = frame.size.width * CGFloat(current)
			collectionView?.setContentOffset(CGPoint(x: offset, y: 0), animated: true)
		}
	}
	
	public func showVideo(name: String) {
		print("PLAY VIDEO \(name)")
	}
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
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
	
	
	// MARK: - Collection View
	
	public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
		return 1
	}
	
	public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return items?.count ?? 0
	}
	
	public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
		let item = items![indexPath.row]
		
		// welcome cell
		if let item = item as? StudyIntroWelcomeItem {
			let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.dynamicType.cellReuseIdentifier, forIndexPath: indexPath) as! StudyIntroWelcomeCell
			cell.item = item
			cell.onVideoTap = { video in
				self.showVideo(video)
			}
			return cell
		}
		
		// video cell
		if let item = item as? StudyIntroVideoItem {
			let cell = collectionView.dequeueReusableCellWithReuseIdentifier(item.dynamicType.cellReuseIdentifier, forIndexPath: indexPath) as! StudyIntroVideoCell
			cell.item = item
			cell.onVideoTap = { video in
				self.showVideo(video)
			}
			return cell
		}
		
		// default: html cell
		let html = item as! StudyIntroHTMLItem
		let cell = collectionView.dequeueReusableCellWithReuseIdentifier(html.dynamicType.cellReuseIdentifier, forIndexPath: indexPath) as! StudyIntroHTMLCell
		cell.item = html
		return cell
	}
	
	
	// MARK: - Scroll View
	
	public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
		if let pageWidth = collectionView?.frame.size.width, let offset = collectionView?.contentOffset.x {
			pageControl?.currentPage = Int((offset + pageWidth / 2) / pageWidth)
		}
	}
}

