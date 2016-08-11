//
//  SystemPermissionTableViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/18/16.
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
Table view controller displaying one cell per system service that access to should be granted. Each cell shows an active "Allow" button
or a disabled "Granted" button for the services you define, allowing users to grant access to select system services.

Assign an array of `SystemService` instances to your controller's `services` property, then present the view controller to the user.
*/
public class SystemPermissionTableViewController: UITableViewController {
	
	lazy var permissionRequester = SystemServicePermissioner()
	
	/// The services to request access to.
	public var services: [SystemService]?
	
	
	public override init(style: UITableViewStyle) {
		super.init(style: style)
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	
	// MARK: - Data
	
	func serviceAtIndexPath(_ indexPath: IndexPath) -> SystemService? {
		if let services = services {
			if (indexPath as NSIndexPath).row < services.count {
				return services[(indexPath as NSIndexPath).row]
			}
		}
		return nil
	}
	
	
	// MARK: - View Tasks
	
	public override func viewDidLoad() {
		super.viewDidLoad()
		tableView.translatesAutoresizingMaskIntoConstraints = false
		tableView.delegate = self
		tableView.dataSource = self
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 200.0
		tableView.register(PermissionRequestTableViewCell.self, forCellReuseIdentifier: "MainCell")
	}
	
	
	// MARK: - Table View Data Source
	
	public override func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return services?.count ?? 0
	}
	
	public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "MainCell", for: indexPath) as! PermissionRequestTableViewCell
		cell.selectionStyle = .none
		if let service = serviceAtIndexPath(indexPath) {
			cell.setup(for: service, permissioner: permissionRequester, viewController: self)
		}
		return cell
	}
}

