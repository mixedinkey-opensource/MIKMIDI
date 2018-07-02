//
//  ViewController.swift
//  MIDI Testbed
//
//  Created by Andrew R Madsen on 7/1/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

import Cocoa
import MIKMIDI

extension Data {
    init?(hexString: String) {
        let len = hexString.count / 2
        var data = Data(capacity: len)
        for i in 0..<len {
            let j = hexString.index(hexString.startIndex, offsetBy: i*2)
            let k = hexString.index(j, offsetBy: 2)
            let bytes = hexString[j..<k]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
        }
        self = data
    }
    
    var hexString: String {
        return map { String(format: "%02x", $0) }
            .joined(separator: "")
    }
}

class ViewController: NSViewController, MIKMIDIConnectionManagerDelegate {
    
    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        createConnectionManager()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        createConnectionManager()
    }
    
    // MARK: Actions
    
    @IBAction func clearOutput(_ sender: Any) {
        textView.string = ""
    }
    
    @IBAction func sendSysex(_ sender: Any) {
        let commandString = commandComboBox.stringValue.replacingOccurrences(of: " ", with: "")
        guard commandString.count > 0 else { return }
        guard let data = Data(hexString: commandString) else { return }

        var packet = MIKMIDIPacketCreate(mach_absolute_time(), UInt16(data.count), Array(data) as [NSNumber])
        let command = MIKMIDICommand(midiPacket: &packet)
        
        guard let device = device else { return }
        let destinations = device.entities.flatMap { $0.destinations }
        for destination in destinations {
            do {
                try deviceManager.send([command], to: destination)
            } catch {
                NSLog("Unable to send command \(command) to endpoint \(destination): \(error)")
            }
        }
    }
    
    @IBAction func commandSelected(_ sender: NSComboBox) {
        guard let selectedValue = sender.objectValueOfSelectedItem as? String,
            let command = availableCommands.filter({ $0["name"] == selectedValue }).first,
            let value = command["value"] else {
                return
        }
        sender.stringValue = value
        sendSysex(sender)
    }
    
    // MARK: MIKMIDIConnectionManagerDelegate
    
    func connectionManager(_ manager: MIKMIDIConnectionManager, shouldConnectToNewlyAddedDevice device: MIKMIDIDevice) -> MIKMIDIAutoConnectBehavior {
        return .doNotConnect
    }
    
    // MARK: Private
    
    private func handle(midiCommand: MIKMIDICommand) {
        guard let textFieldString = self.textView.textStorage?.mutableString else { return }
        textFieldString.append("Received: \(midiCommand)\n")
        textView.scrollToEndOfDocument(self)
    }
    
    private func createConnectionManager() {
        connectionManager = MIKMIDIConnectionManager(name: "com.mixedinkey.MIDITestbed.ConnectionManager", delegate: self) { [weak self] (source, commands) in
            for command in commands where command is MIKMIDIChannelVoiceCommand {
                self?.handle(midiCommand: command as! MIKMIDIChannelVoiceCommand)
            }
        }
        connectionManager.automaticallySavesConfiguration = false
    }
    
    // MARK: Properties
    
    @objc private dynamic var connectionManager: MIKMIDIConnectionManager!
    private let deviceManager = MIKMIDIDeviceManager.shared
    
    @objc private dynamic var device: MIKMIDIDevice? {
        willSet {
            if let device = device {
                connectionManager.disconnect(from: device)
            }
        }
        
        didSet {
            if let device = device {
                do {
                    try connectionManager.connect(to: device)
                } catch {
                    NSApp.presentError(error)
                }
            }
        }
    }
    
    @objc dynamic lazy var availableCommands: [[String : String]] = {
        let identityRequest = MIKMIDISystemExclusiveCommand.identityRequest()
        return [["name" : "Identity Request",
                 "value" : identityRequest.data.hexString]]
    }()
    
    // MARK: Outlets
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var commandComboBox: NSComboBox!
    
}

