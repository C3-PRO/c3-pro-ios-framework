//
//  EligibilityStatusViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 22/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit
import ResearchKit


/**
View controller to inform about eligible or ineligible status.

Simple implementation, you must assign all properties before the view is loaded, dynamic changes are not currently supported!
*/
public class EligibilityStatusViewController: UIViewController {
	
	public var imageName = "logo_disease"
	
	/// Text to show at the top, bold.
	public var titleText: String?
	
	/// Text to show below the title, in normal body font but dark grey.
	public var subText: String?
	
	var actionButton: UIButton?
	
	/// To inform the receiver that the action button cannot yet be enabled.
	public var waitingForAction = false {
		didSet {
			actionButton?.enabled = !waitingForAction
		}
	}
	
	/// The title of the one and only action button, which appears at the bottom **if** `onActionButtonTap` is defined.
	public var actionButtonTitle = NSLocalizedString("Start Consent", comment: "Start Consent button title")
	
	/// Action to perform when the one and only action button is tapped.
	public var onActionButtonTap: ((controller: UIViewController) -> Void)? {
		didSet {
			actionButton?.hidden = nil == onActionButtonTap
		}
	}
	
	
	// MARK: - Actions
	
	func didTapActionButton(button: UIButton) {
		if let exec = onActionButtonTap {
			exec(controller: self)
		}
	}
	
	
	// MARK: - View Tasks
	
	public override func loadView() {
		super.loadView()
		view.backgroundColor = UIColor.whiteColor()
		
		let desc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
		
		let content = UIView()
		content.translatesAutoresizingMaskIntoConstraints = false
		
		// logo image
		let img = UIImageView(image: UIImage(named: imageName))
		img.translatesAutoresizingMaskIntoConstraints = false
		content.addSubview(img)
		content.addConstraint(NSLayoutConstraint(item: img, attribute: .Top, relatedBy: .Equal, toItem: content, attribute: .Top, multiplier: 1.0, constant: 0.0))
		content.addConstraint(NSLayoutConstraint(item: img, attribute: .CenterX, relatedBy: .Equal, toItem: content, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
		
		// text labels
		var lastView: UIView = img
		if let text = titleText {
			let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			label.numberOfLines = 0
			label.textAlignment = .Center
			label.font = UIFont(descriptor: desc.fontDescriptorWithSymbolicTraits([.TraitBold]), size: desc.pointSize)
			label.text = text
			
			content.addSubview(label)
			content.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options: [], metrics: nil, views: ["label": label]))
			content.addConstraint(NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: lastView, attribute: .Bottom, multiplier: 1.0, constant: 20.0))
			lastView = label
		}
		
		if let text = subText {
			let label = UILabel()
			label.translatesAutoresizingMaskIntoConstraints = false
			label.numberOfLines = 0
			label.textAlignment = .Center
			label.textColor = UIColor.darkGrayColor()
			label.font = UIFont(descriptor: desc, size: desc.pointSize)
			label.text = text
			
			content.addSubview(label)
			content.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[label]-|", options: [], metrics: nil, views: ["label": label]))
			content.addConstraint(NSLayoutConstraint(item: label, attribute: .Top, relatedBy: .Equal, toItem: lastView, attribute: .Bottom, multiplier: 1.0, constant: 20.0))
			lastView = label
		}
		content.addConstraint(NSLayoutConstraint(item: lastView, attribute: .Bottom, relatedBy: .Equal, toItem: content, attribute: .Bottom, multiplier: 1.0, constant: 0.0))
		
		// button
		let button = BorderedButton()
		button.translatesAutoresizingMaskIntoConstraints = false
		button.setTitle(actionButtonTitle, forState: .Normal)
		button.hidden = nil == onActionButtonTap
		button.enabled = !waitingForAction
		button.addTarget(self, action: "didTapActionButton:", forControlEvents: .TouchUpInside)
		actionButton = button
		
		// main layout
		view.addSubview(content)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[content]-|", options: [], metrics: nil, views: ["content": content]))
		view.addConstraint(NSLayoutConstraint(item: content, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1.0, constant: 0.0))
		view.addSubview(button)
		view.addConstraint(NSLayoutConstraint(item: button, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1.0, constant: 0.0))
		view.addConstraint(NSLayoutConstraint(item: button, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 180.0))
		view.addConstraint(NSLayoutConstraint(item: button, attribute: .Bottom, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Top, multiplier: 1.0, constant: -20.0))
	}
}

