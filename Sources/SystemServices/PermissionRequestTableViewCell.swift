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
			actionButton?.isEnabled = (nil == actionCallback)
		}
	}
	
	public var actionCallback: ((button: UIButton) -> Void)? {
		didSet {
			actionButton?.isEnabled = (nil != actionCallback)
			if let button = actionButton {
				button.setTitle("Allow".c3_localized("Button to enable certain system services"), for: UIControlState())
				button.setTitle("Granted".c3_localized("Disabled button when permissions were granted"), for: .disabled)
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
		actionButton?.isEnabled = (nil != actionCallback)
		commentLabel?.textColor = UIColor.black
	}
	
	
	// MARK: - Action
	
	/**
	Configure the cell to represent a given service and make its button request access to the given service via the permissioner provided.
	
	- parameter service:      The service to represent
	- parameter permissioner: The permissioner to use to request permission
	*/
	public func setup(for service: SystemService, permissioner: SystemServicePermissioner, viewController vc: UIViewController) {
		titleLabel?.text = service.description
		commentLabel?.text = service.usageReason
		if permissioner.hasPermissionForService(service) {
			viewController = nil
			actionCallback = nil
		}
		else {
			viewController = vc
			actionCallback = { button in
				permissioner.requestPermission(for: service) { [weak self] error in
					if let error = error {
						self?.indicateError(error, for: service)
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
	public func performAction(_ sender: UIButton) {
		actionCallback?(button: sender)
	}
	
	/**
	Indicated that something went wrong when requesting for permission to a given service.
	
	This method renders the error in place of the system service description, turning the text red, and calling
	`showRecoveryInstructionsForService(service:fromViewController)` to show next steps.
	
	- parameter error:   The error that occurred
	- parameter service: The system service that was affected
	*/
	public func indicateError(_ error: Error, for service: SystemService) {
		commentLabel?.text = "\(error)."
		commentLabel?.textColor = UIColor.red
		actionButton?.setTitle("Try Again".c3_localized("Button title"), for: UIControlState())
		contentView.setNeedsLayout()
		contentView.layoutIfNeeded()
		
		if let viewController = viewController {
			showRecoveryInstructions(for: service, from: viewController)
		}
	}
	
	/**
	Show how to recover from failure to enable a certain service.
	
	- parameter service:        The system service that was affected
	- parameter viewController: The view controller to use for instruction presentation
	*/
	public func showRecoveryInstructions(for service: SystemService, from viewController: UIViewController) {
		let alert = UIAlertController(title: service.description, message: service.localizedHowToReEnable, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK".c3_localized("Alert button title"), style: .cancel, handler: nil))
		if service.wantsAppSettingsPane, let url = URL(string: UIApplicationOpenSettingsURLString) {
			alert.addAction(UIAlertAction(title: "Open Settings App".c3_localized, style: .default) { action in
				UIApplication.shared.openURL(url)
			})
		}
		viewController.present(alert, animated: true, completion: nil)
	}
	
	
	// MARK: UI
	
	func setupUI() {
		if nil == titleLabel {
			let ttl = UILabel()
			ttl.translatesAutoresizingMaskIntoConstraints = false
			if #available(iOS 9.0, *) {
				ttl.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleTitle1)
			}
			else {
				ttl.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleHeadline)
			}
			ttl.textAlignment = .center
			ttl.minimumScaleFactor = 0.7
			contentView.addSubview(ttl)
			contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[ttl]-|", options: [], metrics: nil, views: ["ttl": ttl]))
			contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-(15)-[ttl]", options: [], metrics: nil, views: ["ttl": ttl]))
			ttl.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
			titleLabel = ttl
		}
		if nil == commentLabel {
			let cmnt = UILabel()
			cmnt.translatesAutoresizingMaskIntoConstraints = false
			cmnt.font = UIFont.preferredFont(forTextStyle: UIFontTextStyleBody)
			cmnt.textAlignment = .center
			cmnt.numberOfLines = 0
			contentView.addSubview(cmnt)
			contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "|-[cmnt]-|", options: [], metrics: nil, views: ["cmnt": cmnt]))
			contentView.addConstraint(NSLayoutConstraint(item: cmnt, attribute: .top, relatedBy: .equal, toItem: titleLabel!, attribute: .bottom, multiplier: 1, constant: 10))
			commentLabel = cmnt
		}
		if nil == actionButton {
			let btn = BorderedButton()
			btn.translatesAutoresizingMaskIntoConstraints = false
			btn.setTitle("Allow".c3_localized, for: UIControlState())
			btn.addTarget(self, action: #selector(PermissionRequestTableViewCell.performAction(_:)), for: .touchUpInside)
			contentView.addSubview(btn)
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .centerX, relatedBy: .equal, toItem: contentView, attribute: .centerX, multiplier: 1, constant: 0))
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .width, relatedBy: .greaterThanOrEqual, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 150))
			contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[cmnt]-(20)-[btn]-(20)-|", options: [], metrics: nil, views: ["cmnt": commentLabel!, "btn": btn]))
			btn.setContentHuggingPriority(UILayoutPriorityDefaultHigh, for: .vertical)
			actionButton = btn
		}
		super.updateConstraints()
	}
}

