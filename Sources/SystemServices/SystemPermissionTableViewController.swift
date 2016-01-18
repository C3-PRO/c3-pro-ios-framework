//
//  SystemPermissionTableViewController.swift
//  C3PRO
//
//  Created by Pascal Pfiffner on 1/18/16.
//  Copyright © 2016 Boston Children's Hospital. All rights reserved.
//

import UIKit


/**
Table view controller displaying one cell per system service that access to should be granted. Each cell shows an active "Allow" button
or a disabled "Granted" button for the services you define, allowing users to grant access to select system services.
*/
public class SystemPermissionTableViewController: UITableViewController {
	
	lazy var permissionRequester = SystemServicePermissioner()
	
	/// The services to request access to.
	public var services: [SystemService]?
	
	
	public override init(style: UITableViewStyle) {
		super.init(style: style)
	}
	
	public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
	}
	
	public required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}
	
	
	// MARK: - Data
	
	func serviceAtIndexPath(indexPath: NSIndexPath) -> SystemService? {
		if let services = services {
			if indexPath.row < services.count {
				return services[indexPath.row]
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
		tableView.registerClass(PermissionRequestTableViewCell.self, forCellReuseIdentifier: "MainCell")
	}
	
	
	// MARK: - Table View Data Source
	
	public override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
		return 1
	}
	
	public override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return services?.count ?? 0
	}
	
	public override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCellWithIdentifier("MainCell", forIndexPath: indexPath) as! PermissionRequestTableViewCell
		cell.selectionStyle = .None
		if let service = serviceAtIndexPath(indexPath) {
			cell.setupForService(service, permissioner: permissionRequester, viewController: self)
		}
		return cell
	}
}

