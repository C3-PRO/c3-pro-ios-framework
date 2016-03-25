//
//  SystemPermissionStepViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/15/16.
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
import ResearchKit


/**
A view controller for a `SystemPermissionStep`.

You do not need to manually create this view controller, it is automatically created when you add a `SystemPermissionStep` to a task.

Displays a list of system services that the app would like to have access to. Each service comes with an “Allow” button that the user can
press to be prompted for access. Services to which access has already been granted will show up with a disabled button.
*/
public class SystemPermissionStepViewController: ORKStepViewController, UITableViewDelegate, UITableViewDataSource {
	
	var tableView: UITableView!
	
	lazy var permissionRequester = SystemServicePermissioner()
	
	
	public override init(step: ORKStep?) {
		super.init(step: step)
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	
	// MARK: - Data
	
	func serviceAtIndexPath(indexPath: NSIndexPath) -> SystemService? {
		if let step = step as? SystemPermissionStep, let services = step.services {
			if indexPath.row < services.count {
				return services[indexPath.row]
			}
		}
		else {
			c3_warn("No `SystemPermissionStep` is associated with \(self)")
		}
		return nil
	}
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		createUI()
		tableView.registerClass(PermissionRequestTableViewCell.self, forCellReuseIdentifier: "MainCell")
	}
	
	public override func viewWillAppear(animated: Bool) {
		super.viewWillAppear(animated)
		if hasNextStep() {
			let title = ORKBundle().localizedStringForKey("BUTTON_NEXT", value: "BUTTON_NEXT", table: "ResearchKit")
			let next = UIBarButtonItem(title: title, style: .Plain, target: self, action: #selector(UIWebView.goForward))
			self.navigationItem.rightBarButtonItem = next
		}
		else {
			let done = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: #selector(UIWebView.goForward))
			self.navigationItem.rightBarButtonItem = done
		}
	}
	
	func createUI() {
		guard nil == tableView else {
			return
		}
		
		let tv = UITableView(frame: self.view.bounds, style: .Plain)
		tv.translatesAutoresizingMaskIntoConstraints = false
		tv.delegate = self
		tv.dataSource = self
		tv.rowHeight = UITableViewAutomaticDimension
		tv.estimatedRowHeight = 200.0
		
		view.addSubview(tv)
		view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[tv]|", options: [], metrics: nil, views: ["tv": tv]))
		view.addConstraint(NSLayoutConstraint(item: tv, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: tv, attribute: .Bottom, relatedBy: .Equal, toItem: bottomLayoutGuide, attribute: .Top, multiplier: 1, constant: 0))
		tableView = tv
	}
	
	
	// MARK: - Table View Data Source
	
	public func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (step as? SystemPermissionStep)?.services?.count ?? 0
	}
	
	public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("MainCell", forIndexPath: indexPath) as! PermissionRequestTableViewCell
		cell.selectionStyle = .None
		if let service = serviceAtIndexPath(indexPath) {
			cell.setupForService(service, permissioner: permissionRequester, viewController: self)
		}
		return cell
	}
}

