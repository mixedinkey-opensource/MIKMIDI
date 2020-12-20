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

    func FullDisconnect() {
        Disconnect()
        selectedIndex = -1
    }

    func Disconnect() {
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
            Disconnect()
            hasConnection = false
            previousIndex = -1
            return
        }

        Disconnect()
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

        if presetMessageId >= 0 && presetMessageId < supportedCommands.count && connectedDevice != nil {

            if let cmd = supportedCommands[presetMessageId].Command {
                sendCommand(cmd: cmd)
            } else {
                let cmd = commandFromString(command: command)
                sendCommand(cmd: cmd)
            }

        }
    }

    func sendCommand(cmd: MIKMIDICommand) {
        do {
            let dest = connectedDevice!.entities.first!.destinations.first!
            try deviceManager.send([cmd], to: dest)
            logText.append("sent: \(cmd)\n")
        } catch {
            print(error)
        }
    }

    func commandFromString(command: String) -> MIKMIDICommand {

        var byteChars: [Int8] = [ 0, 0, 0]
        var packet = MIDIPacket()
        packet.timeStamp = 0
        packet.length    = UInt16((command.count + ((command.count % 2) * 2)) / 2)

        if packet.length > 0 {
            var data = Array(repeating: UInt8(0), count: Int(packet.length))
            for i in 0..<Int(packet.length) {
                byteChars[0] = Int8((command as NSString).character(at: i*2))
                byteChars[1] = Int8((command as NSString).character(at: i*2+1))
                data[i] = UInt8(strtol(byteChars, nil, 16))
            }
            packet.data = packetDataFromBytes(data: data)
        }

        let packetPtr = UnsafeMutablePointer<MIDIPacket>.allocate(capacity: 1)
        packetPtr.initialize(from: &packet, count: 1)

        return MIKMIDICommand.init(midiPacket: packetPtr)
    }

}
