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
open class SystemPermissionStepViewController: ORKStepViewController, UITableViewDelegate, UITableViewDataSource {
	
	var tableView: UITableView!
	
	lazy var permissionRequester = SystemServicePermissioner()
	
	override public init(step: ORKStep, result: ORKResult) {
		super.init(step: step, result: result)
	}
	
	override public init(step: ORKStep?) {
		super.init(step: step)
	}
	
	override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}

	public required init?(coder aDecoder: NSCoder) {
	    super.init(coder: aDecoder)
	}
	
	
	// MARK: - Data
	
	func service(at indexPath: IndexPath) -> SystemService? {
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
	
	override open func viewDidLoad() {
		super.viewDidLoad()
		createUI()
		tableView.register(PermissionRequestTableViewCell.self, forCellReuseIdentifier: "MainCell")
	}
	
	override open func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if hasNextStep() {
			let title = "Next"; // FIXME: no longer available: ORKBundle().localizedStringForKey("BUTTON_NEXT", value: "BUTTON_NEXT", table: "ResearchKit")
			let next = UIBarButtonItem(title: title, style: .plain, target: self, action: #selector(UIWebView.goForward))
			self.navigationItem.rightBarButtonItem = next
		}
		else {
			let done = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(UIWebView.goForward))
			self.navigationItem.rightBarButtonItem = done
		}
	}
	
	func createUI() {
		guard nil == tableView else {
			return
		}
		
		let tv = UITableView(frame: self.view.bounds, style: .plain)
		tv.translatesAutoresizingMaskIntoConstraints = false
		tv.delegate = self
		tv.dataSource = self
		tv.rowHeight = UITableViewAutomaticDimension
		tv.estimatedRowHeight = 200.0
		
		view.addSubview(tv)
		view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[tv]|", options: [], metrics: nil, views: ["tv": tv]))
		view.addConstraint(NSLayoutConstraint(item: tv, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0))
		view.addConstraint(NSLayoutConstraint(item: tv, attribute: .bottom, relatedBy: .equal, toItem: bottomLayoutGuide, attribute: .top, multiplier: 1, constant: 0))
		tableView = tv
	}
	
	
	// MARK: - Table View Data Source
	
	open func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	open func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return (step as? SystemPermissionStep)?.services?.count ?? 0
	}
	
	open func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as! PermissionRequestTableViewCell
		cell.selectionStyle = .none
		if let service = service(at: indexPath) {
			cell.setup(for: service, permissioner: permissionRequester, viewController: self)
		}
		return cell
	}
}

