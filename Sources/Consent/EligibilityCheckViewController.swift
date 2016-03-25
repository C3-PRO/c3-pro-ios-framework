//
//  EligibilityCheckViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 22/10/15.
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
View controller presenting all eligibility criteria provided in the receiver`s `requirements` property, allowing the user to proceed to a
summary page that informs of eligibility and allows to proceed to to consenting or not.
*/
public class EligibilityCheckViewController: UITableViewController {
	
	var nextButton: UIBarButtonItem?
	
	/// The eligibility criteria.
	public var requirements: [EligibilityRequirement]?
	
	/// Set this string to override the title message. Defaults to "You are eligible to join the study".
	public var eligibleTitle: String?
	
	/// Override point for the default eligible message "Tap the button below to begin the consent process".
	public var eligibleMessage: String?
	
	/// Override point for the default ineligible message "Thank you for your interest!\nUnfortunately, you are not eligible to join [...]".
	public var ineligibleMessage: String?
	
	/// Block executed if all eligibility requirements are met and the user taps the "Start Consent" button.
	public var onStartConsent: ((viewController: EligibilityCheckViewController) -> Void)?
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		tableView.registerClass(EligibilityCell.self, forCellReuseIdentifier: "EligibilityCell")
		tableView.estimatedRowHeight = 120.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		let next = UIBarButtonItem(title: "Next".c3_localized("Next step"), style: .Plain, target: self, action: #selector(EligibilityCheckViewController.verifyEligibility))
		next.enabled = false
		navigationItem.rightBarButtonItem = next
		nextButton = next
		enableDisableNext()
	}
	
	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if isMovingToParentViewController(), let eligible = isEligible() where eligible {
			showEligibleAnimated(true)
		}
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
		}
		nextButton?.enabled = true
	}
	
	func verifyEligibility() {
		if let eligible = isEligible() {
			if eligible {
				showEligibleAnimated(true)
			}
			else {
				showIneligibleAnimated(true)
			}
		}
		else {
			nextButton?.enabled = false
		}
	}
	
	/** Determine current eligibility status.
	- returns: True if all requirements are met, false if at least one is not met, nil if not all have been answered yet
	*/
	func isEligible() -> Bool? {
		if let reqs = requirements {
			for requirement in reqs {
				if let met = requirement.met {
					if met != requirement.mustBeMet {
						return false
					}
				}
				else {
					return nil
				}
			}
		}
		
		// all requirements answered and met (or none to meet)
		return true
	}
	
	/**
	Eligible.
	
	Push `EligibilityStatusViewController` informing about eligibility and presenting the “Start Consent” button that will execute the
	`onStartConsent` block.
	
	- parameter animated: Whether to animate the push
	*/
	public func showEligibleAnimated(animated: Bool) {
		let vc = EligibilityStatusViewController()
		vc.titleText = eligibleTitle ?? "You are eligible to join the study".c3_localized
		vc.subText = eligibleMessage ?? "Tap the button below to begin the consent process".c3_localized
		vc.onActionButtonTap = { controller in
			if let exec = self.onStartConsent {
				exec(viewController: self)
			}
			else {
				c3_warn("Tapped “Start Consent” but `onStartConsent` is not defined")
			}
		}
		navigationController?.pushViewController(vc, animated: true)
	}
	
	/**
	Ineligible.
	
	Push EligibilityStatusViewController informing about non-eligibility, removing the other status and check view controllers from the
	stack so that if pressing "< Back", the user lands back at where eligibility checking started.
	
	- parameter animated: Whether to animate the push
	*/
	public func showIneligibleAnimated(animated: Bool) {
		let vc = EligibilityStatusViewController()
		vc.subText = ineligibleMessage ?? "Thank you for your interest!\nUnfortunately, you are not eligible to join this study at this time.".c3_localized
		
		if let navi = navigationController {
			var vcs = navi.viewControllers.filter() { !($0 is EligibilityStatusViewController || $0 is EligibilityCheckViewController) }
			vcs.append(vc)
			navi.setViewControllers(vcs, animated: true)
		}
		else {
			c3_warn("Incredible error, my navigation controller disappeared! I'm \(self)")
		}
	}
	
	
	// MARK: - Table View Data Source
	
	public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return requirements?.count ?? 0
	}
	
	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("EligibilityCell", forIndexPath: indexPath) as! EligibilityCell
		cell.item = requirements![indexPath.section]
		cell.onButtonPress = { button in
			self.enableDisableNext()
		}
		return cell
	}
}


/**
Table view cell displaying an eligibility requirement.
*/
class EligibilityCell: UITableViewCell {
	
	var titleLabel: UILabel?
	
	var yesButton: UIButton?
	
	var noButton: UIButton?
	
	/// The requirement to show.
	var item: EligibilityRequirement? {
		didSet {
			if let item = item {
				titleLabel?.text = item.title
			}
		}
	}
	
	var onButtonPress: ((button: UIButton) -> Void)?
	
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		selectionStyle = .None
		
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
		yes.addTarget(self, action: #selector(EligibilityCell.buttonDidPress(_:)), forControlEvents: .TouchUpInside)
		no.addTarget(self, action: #selector(EligibilityCell.buttonDidPress(_:)), forControlEvents: .TouchUpInside)
		
		let desc = UIFontDescriptor.preferredFontDescriptorWithTextStyle(UIFontTextStyleBody)
		yes.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		no.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		yes.setTitle("Yes".c3_localized("Yes as in yes-i-meet-this-requirement"), forState: .Normal)
		no.setTitle("No".c3_localized("No as in no-i-dont-meet-this-requirement"), forState: .Normal)
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

