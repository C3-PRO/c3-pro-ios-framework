//
//  PermissionRequestTableViewCell.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/16/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
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
A cell of this class provides some information about a system service and has an "Allow" button that can be pressed to request permission
to the respective system service.

Use `setupForService(service:permissioner:viewController:)` to setup the cell. It will automatically use the permissioner to ask for
permission when the user taps the “Allow” button, show when enabling is not possible and also show an alert informing about how to recover
from the error.
*/
public class PermissionRequestTableViewCell: UITableViewCell {
	
	weak var viewController: UIViewController?
	
	@IBOutlet var titleLabel: UILabel?
	
	@IBOutlet var commentLabel: UILabel?
	
	@IBOutlet var actionButton: UIButton? {
		didSet {
			actionButton?.enabled = (nil == actionCallback)
		}
	}
	
	public var actionCallback: ((button: UIButton) -> Void)? {
		didSet {
			actionButton?.enabled = (nil != actionCallback)
			if let button = actionButton {
				button.setTitle("Allow".c3_localized("Button to enable certain system services"), forState: .Normal)
				button.setTitle("Granted".c3_localized("Disabled button when permissions were granted"), forState: .Disabled)
			}
		}
	}
	
	public override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupUI()
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	
	// MARK: - View
	
	public override func prepareForReuse() {
		resetUI()
		super.prepareForReuse()
	}
	
	func resetUI() {
		actionButton?.enabled = (nil != actionCallback)
		commentLabel?.textColor = UIColor.blackColor()
	}
	
	
	// MARK: - Action
	
	/**
	Configure the cell to represent a given service and make its button request access to the given service via the permissioner provided.
	
	- parameter service: The service to represent
	- parameter permissioner: The permissioner to use to request permission
	*/
	public func setupForService(service: SystemService, permissioner: SystemServicePermissioner, viewController vc: UIViewController) {
		titleLabel?.text = service.description
		commentLabel?.text = service.usageReason
		if permissioner.hasPermissionForService(service) {
			viewController = nil
			actionCallback = nil
		}
		else {
			viewController = vc
			actionCallback = { button in
				permissioner.requestPermissionForService(service) { [weak self] error in
					if let error = error {
						self?.indicateError(error, forService: service)
					}
					else {
						self?.commentLabel?.text = service.usageReason
						self?.actionCallback = nil
						self?.viewController = nil
						self?.resetUI()
					}
				}
			}
		}
	}
	
	/** Perform the action assigned to the button; you normally don't need to use this method yourself. */
	public func performAction(sender: UIButton) {
		actionCallback?(button: sender)
	}
	
	/**
	Indicated that something went wrong when requesting for permission to a given service.
	
	This method renders the error in place of the system service description, turning the text red, and calling
	`showRecoveryInstructionsForService(service:fromViewController)` to show next steps.
	
	- parameter error: The error that occurred
	- parameter forService: The system service affected
	*/
	public func indicateError(error: ErrorType, forService service: SystemService) {
		commentLabel?.text = "\(error)."
		commentLabel?.textColor = UIColor.redColor()
		actionButton?.setTitle("Try Again".c3_localized("Button title"), forState: .Normal)
		contentView.setNeedsLayout()
		contentView.layoutIfNeeded()
		
		if let viewController = viewController {
			showRecoveryInstructionsForService(service, fromViewController: viewController)
		}
	}
	
	/**
	Show how to recover from failure to enable a certain service.
	
	- parameter service: The system service that was affected
	- parameter fromViewController: The view controller to use for instruction presentation
	*/
	public func showRecoveryInstructionsForService(service: SystemService, fromViewController viewController: UIViewController) {
		let alert = UIAlertController(title: service.description, message: service.localizedHowToReEnable, preferredStyle: .Alert)
		alert.addAction(UIAlertAction(title: "OK".c3_localized("Alert button title"), style: .Cancel, handler: nil))
		if service.wantsAppSettingsPane, let url = NSURL(string: UIApplicationOpenSettingsURLString) {
			alert.addAction(UIAlertAction(title: "Open Settings App".c3_localized, style: .Default) { action in
				UIApplication.sharedApplication().openURL(url)
			})
		}
		viewController.presentViewController(alert, animated: true, completion: nil)
	}
	
	
	// MARK: UI
	
	func setupUI() {
		if nil == titleLabel {
			let ttl = UILabel()
			ttl.translatesAutoresizingMaskIntoConstraints = false
			if #available(iOS 9.0, *) {
				ttl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleTitle1)
			}
			else {
				ttl.font = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline)
			}
			ttl.textAlignment = .Center
			ttl.minimumScaleFactor = 0.7
			contentView.addSubview(ttl)
			contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[ttl]-|", options: [], metrics: nil, views: ["ttl": ttl]))
			contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-(15)-[ttl]", options: [], metrics: nil, views: ["ttl": ttl]))
			ttl.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Vertical)
			titleLabel = ttl
		}
		if nil == commentLabel {
			let cmnt = UILabel()
			cmnt.translatesAutoresizingMaskIntoConstraints = false
			cmnt.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
			cmnt.textAlignment = .Center
			cmnt.numberOfLines = 0
			contentView.addSubview(cmnt)
			contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|-[cmnt]-|", options: [], metrics: nil, views: ["cmnt": cmnt]))
			contentView.addConstraint(NSLayoutConstraint(item: cmnt, attribute: .Top, relatedBy: .Equal, toItem: titleLabel!, attribute: .Bottom, multiplier: 1, constant: 10))
			commentLabel = cmnt
		}
		if nil == actionButton {
			let btn = BorderedButton()
			btn.translatesAutoresizingMaskIntoConstraints = false
			btn.setTitle("Allow".c3_localized, forState: .Normal)
			btn.addTarget(self, action: "performAction:", forControlEvents: .TouchUpInside)
			contentView.addSubview(btn)
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0))
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 150))
			contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[cmnt]-(20)-[btn]-(20)-|", options: [], metrics: nil, views: ["cmnt": commentLabel!, "btn": btn]))
			btn.setContentHuggingPriority(UILayoutPriorityDefaultHigh, forAxis: .Vertical)
			actionButton = btn
		}
		super.updateConstraints()
	}
}

