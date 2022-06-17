//
//  ObservedDevices.swift
//  Midi Testbed Swift
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI

// ObservedDevices is used by the TestbedView to list and
// interact with the available midi devices

class ObservedDevices: ObservableObject {

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
                for cmd in commands {
                    self.handleCommand(cmd: cmd)
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

    func handleCommand( cmd: MIKMIDICommand) {
        logText.append("received: \(cmd)\n")
    }

    func processCommand(presetMessageId: Int, command: String ) {
        guard (0..<supportedCommands.count).contains(presetMessageId),
              connectedDevice != nil else {
            return
        }

        let command = supportedCommands[presetMessageId].command ?? commandFromString(command: command)
        send(command: command)
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

    func commandFromString(command: String) -> MIKMIDICommand {
        let packetLength = (command.count + ((command.count % 2) * 2)) / 2
        let trimmedCommand = command.trimmingCharacters(in: .whitespaces)
        let data = stride(from: 0, to: trimmedCommand.count, by: 2)
            .map { index -> String in
                let start = trimmedCommand.index(trimmedCommand.startIndex, offsetBy: index)
                let end = trimmedCommand.index(start, offsetBy: 1, limitedBy: trimmedCommand.endIndex) ?? trimmedCommand.endIndex
                return String(trimmedCommand[start...end])
            }
            .compactMap { UInt8($0, radix: 16) }
            .reduce(into: Data(capacity: packetLength)) { partialResult, chunk in
                partialResult.append(chunk)
            }
        var packet = MIDIPacket(timestamp: 0, length: packetLength, data: data)
        let packetPtr = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        packetPtr.initialize(from: &packet, count: 1)
        return MIKMIDICommand(midiPacket: packetPtr)
    }

}
