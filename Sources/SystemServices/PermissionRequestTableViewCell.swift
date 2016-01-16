//
//  PermissionRequestTableViewCell.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/16/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import UIKit


/**
A cell of this class provides some information about a system service and has an "Allow" button that can be pressed to request permission
to the respective system service.
*/
class PermissionRequestTableViewCell: UITableViewCell {
	
	@IBOutlet var titleLabel: UILabel?
	
	@IBOutlet var commentLabel: UILabel?
	
	@IBOutlet var actionButton: UIButton? {
		didSet {
			actionButton?.enabled = (nil == actionCallback)
		}
	}
	
	var actionCallback: ((button: UIButton) -> Void)? {
		didSet {
			actionButton?.enabled = (nil != actionCallback)
			if let button = actionButton {
				button.setTitle(NSLocalizedString(button.enabled ? "Allow" : "Granted", comment: ""), forState: .Normal)
			}
		}
	}
	
	
	override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setupUI()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	override func prepareForReuse() {
		super.prepareForReuse()
		actionButton?.enabled = (nil != actionCallback)
	}
	
	
	// MARK: Action
	
	/**
	Configure the cell to represent a given service and make its button request access to the given service via the permissioner provided.
	
	- parameter service: The service to represent
	- parameter permissioner: The permissioner to use to request permission
	*/
	func setupForService(service: SystemService, permissioner: SystemServicePermissioner) {
		titleLabel?.text = service.name
		commentLabel?.text = service.description
		if permissioner.hasPermissionForService(service) {
			actionCallback = nil
		}
		else {
			actionCallback = { button in
				permissioner.requestPermissionForService(service) { [weak self] error in
					if let error = error {
						self?.commentLabel?.text = "\(error)"
						self?.commentLabel?.textColor = UIColor.redColor()
					}
					else {
						self?.actionCallback = nil
					}
				}
			}
		}
	}
	
	func performAction(sender: UIButton) {
		actionCallback?(button: sender)
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
			btn.setTitle(NSLocalizedString("Allow", comment: ""), forState: .Normal)
			btn.addTarget(self, action: "performAction:", forControlEvents: .TouchUpInside)
			contentView.addSubview(btn)
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .CenterX, relatedBy: .Equal, toItem: contentView, attribute: .CenterX, multiplier: 1, constant: 0))
			contentView.addConstraint(NSLayoutConstraint(item: btn, attribute: .Width, relatedBy: .GreaterThanOrEqual, toItem: nil, attribute: .NotAnAttribute, multiplier: 1, constant: 150))
			contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[cmnt]-(20)-[btn]-(20)-|", options: [], metrics: nil, views: ["cmnt": commentLabel!, "btn": btn]))
			actionButton = btn
		}
		super.updateConstraints()
	}
}

