//
//  DevicesTableViewController.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 11/29/17.
//  Copyright © 2017 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

class DevicesTableViewController: UITableViewController {
	
	// MARK: Overridden
	
	// MARK: Public Methods
	
	// MARK: Actions
	
	@IBAction func toggleConnection(_ sender: UISwitch) {
		let switchRect = sender.convert(sender.bounds, to: tableView)
		guard let indexPath = tableView.indexPathForRow(at: CGPoint(x: switchRect.midX, y: switchRect.midY)),
			let manager = connectionManager else {
				return
		}
		
		let device = manager.availableDevices[indexPath.row]
		let isConnected = manager.connectedDevices.contains(device)
		if (isConnected) {
			manager.disconnect(from: device)
		} else {
			try? manager.connect(to: device)
		}
	}
	
	// MARK: - UITableViewDataSource/Delegate
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return connectionManager?.availableDevices.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
		guard let deviceCell = cell as? DeviceTableViewCell,
			let manager = connectionManager else {
				return cell
		}
		
		let device = manager.availableDevices[indexPath.row]
		deviceCell.deviceLabel.text = device.displayName
		deviceCell.connectionSwitch.isOn = manager.connectedDevices.contains(device)
		
		return deviceCell
	}
	
	// MARK: Private Methods
	
	// MARK: Public Properties
	
	var connectionManagerObservers = [NSKeyValueObservation]()
	var connectionManager: MIKMIDIConnectionManager? {
		willSet {
			connectionManagerObservers = []
		}
		didSet {
			tableView?.reloadData()
			
			if let manager = connectionManager {
				var observer = manager.observe(\MIKMIDIConnectionManager.availableDevices) { [weak self] _, _ in
					self?.tableView?.reloadData()
				}
				connectionManagerObservers.append(observer)
				observer = manager.observe(\MIKMIDIConnectionManager.connectedDevices) { [weak self] _, _ in
					self?.tableView?.reloadData()
				}
				connectionManagerObservers.append(observer)
			}
		}
	}
	
	// MARK: Private Properties
	
	// MARK: Outlets
	
}
