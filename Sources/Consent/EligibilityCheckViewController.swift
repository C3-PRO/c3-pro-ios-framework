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
open class EligibilityCheckViewController: UITableViewController {
	
	var nextButton: UIBarButtonItem?
	
	/// The eligibility criteria.
	open var requirements: [EligibilityRequirement]?
	
	/// Set this string to override the title message. Defaults to "You are eligible to join the study".
	open var eligibleTitle: String?
	
	/// Override point for the default eligible message "Tap the button below to begin the consent process".
	open var eligibleMessage: String?
	
	/// Override point for the default ineligible message "Thank you for your interest!\nUnfortunately, you are not eligible to join [...]".
	open var ineligibleMessage: String?
	
	/// Block executed if all eligibility requirements are met and the user taps the "Start Consent" button.
	open var onStartConsent: ((_ viewController: EligibilityCheckViewController) -> Void)?
	
	
	// MARK: - View Tasks
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(EligibilityCell.self, forCellReuseIdentifier: "EligibilityCell")
		tableView.estimatedRowHeight = 120.0
		tableView.rowHeight = UITableViewAutomaticDimension
		
		let next = UIBarButtonItem(title: "Next".c3_localized("Next step"), style: .plain, target: self, action: #selector(EligibilityCheckViewController.verifyEligibility))
		next.isEnabled = false
		navigationItem.rightBarButtonItem = next
		nextButton = next
		enableDisableNext()
	}
	
	override open func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if isMovingToParentViewController, isEligible() ?? false {
			showEligible(animated: true)
		}
	}
	
	
	// MARK: - Actions
	
	func enableDisableNext() {
		if let reqs = requirements {
			for req in reqs {
				if nil == req.met {
					nextButton?.isEnabled = false
					return
				}
			}
		}
		nextButton?.isEnabled = true
	}
	
	func verifyEligibility() {
		if let eligible = isEligible() {
			if eligible {
				showEligible(animated: true)
			}
			else {
				showIneligible(animated: true)
			}
		}
		else {
			nextButton?.isEnabled = false
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
	open func showEligible(animated: Bool) {
		let vc = EligibilityStatusViewController()
		vc.titleText = eligibleTitle ?? "You are eligible to join the study".c3_localized
		vc.subText = eligibleMessage ?? "Tap the button below to begin the consent process".c3_localized
		vc.onActionButtonTap = { controller in
			if let exec = self.onStartConsent {
				exec(self)
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
	open func showIneligible(animated: Bool) {
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
	
	override open func numberOfSections(in tableView: UITableView) -> Int {
		return requirements?.count ?? 0
	}
	
	override open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 1
	}
	
	override open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "EligibilityCell", for: indexPath) as! EligibilityCell
		cell.item = requirements![(indexPath as NSIndexPath).section]
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
	
	var onButtonPress: ((UIButton) -> Void)?
	
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		selectionStyle = .none
		
		// title label
		let title = UILabel()
		title.translatesAutoresizingMaskIntoConstraints = false
		title.font = UIFont.preferredFont(forTextStyle: .body)
		title.numberOfLines = 0
		title.textAlignment = .center
		title.textColor = UIColor.black
		titleLabel = title
		
		// choice view
		let choice = UIView()
		choice.translatesAutoresizingMaskIntoConstraints = false
		
		// yes and no buttons
		let yes = UIButton(type: .custom)
		let no = UIButton(type: .custom)
		yes.translatesAutoresizingMaskIntoConstraints = false
		no.translatesAutoresizingMaskIntoConstraints = false
		yes.isSelected = false
		no.isSelected = false
		yes.setTitleColor(UIColor.lightGray, for: UIControlState())
		no.setTitleColor(UIColor.lightGray, for: UIControlState())
		yes.setTitleColor(self.tintColor, for: .selected)
		no.setTitleColor(self.tintColor, for: .selected)
		yes.addTarget(self, action: #selector(EligibilityCell.buttonDidPress(_:)), for: .touchUpInside)
		no.addTarget(self, action: #selector(EligibilityCell.buttonDidPress(_:)), for: .touchUpInside)
		
		let desc = UIFontDescriptor.preferredFontDescriptor(withTextStyle: .body)
		yes.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		no.titleLabel?.font = UIFont(descriptor: desc, size: desc.pointSize * 2)
		yes.setTitle("Yes".c3_localized("Yes as in yes-i-meet-this-requirement"), for: UIControlState())
		no.setTitle("No".c3_localized("No as in no-i-dont-meet-this-requirement"), for: UIControlState())
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
		choice.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[yes(==no)][sep(==0.5)][no]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[yes]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[sep]|", options: [], metrics: nil, views: buttons))
		choice.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[no]|", options: [], metrics: nil, views: buttons))
		
		let views = ["title": title, "choice": choice]
		contentView.addSubview(title)
		contentView.addSubview(choice)
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[title]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-[choice]-|", options: [], metrics: nil, views: views))
		contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-[title]-[choice]-|", options: [], metrics: nil, views: views))
		choice.addConstraint(NSLayoutConstraint(item: choice, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 0.0, constant: 80.0))
	}

	required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	
	// MARK: - Button Action
	
	func buttonDidPress(_ sender: UIButton) {
		sender.isSelected = !sender.isSelected
		if yesButton == sender {
			item?.met = true
			noButton?.isSelected = false
		}
		else {
			item?.met = false
			yesButton?.isSelected = false
		}
		
		if let exec = onButtonPress {
			exec(sender)
		}
	}
	
	override func tintColorDidChange() {
		yesButton?.setTitleColor(self.tintColor, for: .selected)
		noButton?.setTitleColor(self.tintColor, for: .selected)
		super.tintColorDidChange()
	}
}

