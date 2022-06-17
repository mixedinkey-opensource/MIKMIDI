//
//  DevicesSelectionViewModel.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI

// DevicesSelectionViewModel is used by the TestbedView to list and
// interact with the available midi devices

class DevicesSelectionViewModel: ObservableObject {

    init() {
        midiDevicesObserver = deviceManager.observe(\.availableDevices) { (_, _) in
            self.availableDevices = self.deviceManager.availableDevices
            self.logText.append("available MIDI devices list has updated\n")
        }
    }

    private var midiDevicesObserver: NSKeyValueObservation?
    private let deviceManager = MIKMIDIDeviceManager.shared
    private var previousIndex: Int = -1
    private var connectionToken: Any?

    @Published var availableDevices = MIKMIDIDeviceManager.shared.availableDevices
    @Published var connectedDevice: MIKMIDIDevice?
    @Published var hasConnection: Bool = false
    @Published var logText: String = defaultLogText

    private var hasChanged: Bool = false

    @Published var selectedIndex: Int = -1 {
        didSet {
            handleConnectionChange()
        }
    }

    func fullDisconnect() {
        disconnect()
        selectedIndex = -1
    }

    func disconnect() {
        if let cd = connectedDevice, let token = connectionToken {
            deviceManager.disconnectConnection(forToken: token)
            hasConnection = false
            connectedDevice = nil
            logText.append("disconnect: \(cd.name!) (\(cd.manufacturer!), \(cd.model!))\n")
        }
    }

    func handleConnectionChange() {

        let ok = selectedIndex > -1 &&
        deviceManager.availableDevices.count > selectedIndex

        if selectedIndex == previousIndex {
            return
        }

        if !ok {
            disconnect()
            hasConnection = false
            previousIndex = -1
            return
        }

        disconnect()
        let nd = deviceManager.availableDevices[selectedIndex]

        do {
            try connectionToken = deviceManager.connect(nd, eventHandler: { (_, commands) in
                for command in commands {
                    self.handle(command: command)
                }
            })
            if !hasChanged {
                hasChanged = true
                logText = ""
            }
            connectedDevice = nd
            previousIndex = selectedIndex
            self.hasConnection = true
            logText.append("connected: \(nd.name!) (\(nd.manufacturer!), \(nd.model!))\n")
        } catch {
            hasConnection = false
            previousIndex = -1
            print(error)
        }
    }

    func handle(command: MIKMIDICommand) {
        logText.append("received: \(command)\n")
    }

    func send(command: MIKMIDICommand) {
        do {
            let dest = connectedDevice!.entities.first!.destinations.first!
            try deviceManager.send([command], to: dest)
            logText.append("sent: \(command)\n")
        } catch {
            NSApp.presentError(error)
        }
    }
}
