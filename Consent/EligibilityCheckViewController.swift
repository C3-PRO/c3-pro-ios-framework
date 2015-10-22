//
//  EligibilityCheckViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 22/10/15.
//  Copyright © 2015 Boston Children's Hospital. All rights reserved.
//

import UIKit


public class EligibilityCheckViewController: UITableViewController {
	
	public var requirements: [ConsentEligibilityRequirement]?
	
	var nextButton: UIBarButtonItem?
	
	/// Set this string to override the title message. Defaults to "You are eligible to join the study".
	public var eligibleTitle: String?
	
	/// Override point for the default eligible message "Tap the button below to begin the consent process".
	public var eligibleMessage: String?
	
	/// Override point for the default ineligible message "Thank you for your interest!\nUnfortunately, you are not eligible to join [...]".
	public var ineligibleMessage: String?
	
	/// Block executed if all eligibility requirements are met and the user taps the "Start Consent" button.
	public var onStartConsent: ((controller: EligibilityCheckViewController) -> Void)?
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		tableView.registerClass(ConsentEligibilityCell.self, forCellReuseIdentifier: "EligibilityCell")
		tableView.estimatedRowHeight = 120.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		let next = UIBarButtonItem(title: NSLocalizedString("Next", comment: "Next step"), style: .Plain, target: self, action: "verifyEligibility")
		next.enabled = false
		navigationItem.rightBarButtonItem = next
		nextButton = next
		enableDisableNext()
	}
	
	
	// MARK: - Actions
	
	func enableDisableNext() {
		if let reqs = requirements {
			for req in reqs {
				if nil == req.met {
					nextButton?.enabled = false
					return
				}
			}
			nextButton?.enabled = true
		}
		else {
			nextButton?.enabled = false
		}
	}
	
	func verifyEligibility() {
		if let reqs = requirements {
			for requirement in reqs {
				if let met = requirement.met {
					if !met {
						showIneligibleAnimated(true)
						return
					}
				}
				else {
					nextButton?.enabled = false
					return
				}
			}
			
			// all requirements checked and met
			showEligibleAnimated(true)
		}
		else {
			nextButton?.enabled = false
		}
	}
	
	public func showEligibleAnimated(animated: Bool) {
		let vc = EligibilityStatusViewController()
		vc.titleText = eligibleTitle ?? NSLocalizedString("You are eligible to join the study", comment: "")
		vc.subText = eligibleMessage ?? NSLocalizedString("Tap the button below to begin the consent process", comment: "")
		vc.onActionButtonTap = { controller in
			if let exec = self.onStartConsent {
				exec(controller: self)
			}
			else {
				chip_warn("Tapped “Start Consent” but `onStartConsent` is not defined")
			}
		}
		navigationController?.pushViewController(vc, animated: true)
	}
	
	public func showIneligibleAnimated(animated: Bool) {
		let vc = EligibilityStatusViewController()
		vc.subText = ineligibleMessage ?? NSLocalizedString("Thank you for your interest!\nUnfortunately, you are not eligible to join this study at this time.", comment: "")
		navigationController?.pushViewController(vc, animated: true)
	}
	
	
	// MARK: - Table View Data Source
	
	public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return requirements?.count ?? 0
	}
	
	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("EligibilityCell", forIndexPath: indexPath) as! ConsentEligibilityCell
		cell.item = requirements![indexPath.section]
		cell.onButtonPress = { button in
			self.enableDisableNext()
		}
		return cell
	}
}


/**
Objects holding and tracking eligibility requirements.
*/
public class ConsentEligibilityRequirement {
	
	/// The question/statement to show when asking about this requirement.
	public let title: String
	
	/// Whether this requirement has been met.
	public var met: Bool? = nil
	
	public init(title: String) {
		self.title = title
	}
}


class ConsentEligibilityCell: UITableViewCell {
	
	var titleLabel: UILabel?
	
	var yesButton: UIButton?
	
	var noButton: UIButton?
	
	var item: ConsentEligibilityRequirement? {
		didSet {
			if let item = item {
				titleLabel?.text = item.title
			}
		}
	}
	
	var onButtonPress: ((button: UIButton) -> Void)?
	
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		
		// title label
		let title = UILabel()
		title.translatesAutoresizingMaskIntoConstraints = false
		title.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
		title.numberOfLines = 0
		title.textAlignment = .Center
		title.textColor = UIColor.blackColor()
		titleLabel = title
		
		// choice view
		let choice = UIView()
		choice.translatesAutoresizingMaskIntoConstraints = false
		
		// yes and no buttons
		let yes = UIButton(type: .Custom)
		let no = UIButton(type: .Custom)
		yes.translatesAutoresizingMaskIntoConstraints = false
		no.translatesAutoresizingMaskIntoConstraints = false
		yes.selected = false
		no.selected = false
		yes.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		no.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
		yes.setTitleColor(self.tintColor, forState: .Selected)
		no.setTitleColor(self.tintColor, forState: .Selected)
		yes.addTarget(self, action: "buttonDidPress:", forControlEvents: .TouchUpInside)
		no.addTarget(self, action: "buttonDidPress:", forControlEvents: .TouchUpInside)
		
		let desc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
		yes.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		no.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		yes.setTitle(NSLocalizedString("Yes", comment: "Yes as in yes-i-meet-this-requirement"), forState: .Normal)
		no.setTitle(NSLocalizedString("No", comment: "No as in no-i-dont-meet-this-requirement"), forState: .Normal)
		let sep = UIView()
		sep.translatesAutoresizingMaskIntoConstraints = false
		sep.backgroundColor = UIColor(white: 0.8, alpha: 1.0)
		yesButton = yes
		noButton = no
		
		// layout
		let buttons = ["yes": yes, "sep": sep, "no": no]
		choice.addSubview(yes)
		choice.addSubview(sep)
		choice.addSubview(no)
		choice.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[yes(==no)][sep(==0.5)][no]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[yes]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[sep]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[no]|", options: [], metrics: nil, views: buttons))
		
		let views = ["title": title, "choice": choice]
		contentView.addSubview(title)
		contentView.addSubview(choice)
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[title]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[choice]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-[title]-[choice]-|", options: [], metrics: nil, views: views))
		choice.addConstraint(NSLayoutConstraint(item: choice, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .NotAnAttribute, multiplier: 0.0, constant: 80.0))
	}

	required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	
	// MARK: - Button Action
	
	func buttonDidPress(sender: UIButton) {
		sender.selected = !sender.selected
		if yesButton == sender {
			item?.met = true
			noButton?.selected = false
		}
		else {
			item?.met = false
			yesButton?.selected = false
		}
		
		if let exec = onButtonPress {
			exec(button: sender)
		}
	}
	
	override func tintColorDidChange() {
		yesButton?.setTitleColor(self.tintColor, forState: .Selected)
		noButton?.setTitleColor(self.tintColor, forState: .Selected)
		super.tintColorDidChange()
	}
}

