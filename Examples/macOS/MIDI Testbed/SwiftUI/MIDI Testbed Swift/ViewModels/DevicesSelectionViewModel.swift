//
//  DevicesSelectionViewModel.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI
import Combine

// DevicesSelectionViewModel is used by the TestbedView to list and
// interact with the available MIDI devices
class DevicesSelectionViewModel: ObservableObject {

    init() {
        deviceManager
            .publisher(for: \.availableDevices, options: .initial)
            .assign(to: &$availableDevices)
    }

    deinit {
        disconnect()
    }

    // MARK: - Public Methods

    func connectToSelectedDevice() {
        guard let selectedDevice = selectedDevice else { return }
        if connectedDevice != nil {
            disconnect()
        }
        do {
            try connectionToken = deviceManager.connect(selectedDevice) { [weak self] (_, commands) in
                for command in commands {
                    self?.handle(command: command)
                }
            }
            connectedDevice = selectedDevice
            logText = "connected: \(selectedDevice.name!) (\(selectedDevice.manufacturer!), \(selectedDevice.model!))\n"
        } catch {
            connectedDevice = nil
            print(error)
        }
    }

    func disconnect() {
        guard let cd = connectedDevice,
              let token = connectionToken else {
            return
        }
        deviceManager.disconnectConnection(forToken: token)
        connectedDevice = nil
        logText.append("disconnect: \(cd.name!) (\(cd.manufacturer!), \(cd.model!))\n")
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

    // MARK: - Private Methods

    private func handleConnectionChange() {
        guard selectedDevice != nil else {
            disconnect()
            return
        }
        connectToSelectedDevice()
    }

    private func handle(command: MIKMIDICommand) {
        logText.append("received: \(command)\n")
    }

    // MARK: - Public Properties

    @Published var availableDevices = MIKMIDIDeviceManager.shared.availableDevices
    @Published var connectedDevice: MIKMIDIDevice?
    @Published var selectedDevice: MIKMIDIDevice? {
        didSet {
            guard selectedDevice != oldValue else { return }
            handleConnectionChange()
        }
    }
    @Published var logText: String = ""

    // MARK: - Private Properties

    private let deviceManager = MIKMIDIDeviceManager.shared
    private var connectionToken: Any?
}
