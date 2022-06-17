//
//  Testbed.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import SwiftUI

struct TestbedView: View {

    @ObservedObject private var devices = ObservedDevices()
    @State private var customMessage: String = ""
    @State private var textFieldDisabled: Bool = false
    @State private var presetMessageId: Int = 0

    var body: some View {

        VStack {
            VStack(alignment: .leading, spacing: nil/*@END_MENU_TOKEN@*/, content: {
                TextView(text: $devices.logText)
                    .frame(width: 615, height: 390, alignment: .topLeading)
                    .border(Color(red: 0.3, green: 0.3, blue: 0.3))
            })
            .padding(.top, 10)
            HStack {
                Picker(selection: $devices.selectedIndex, label: Text("Device")) {
                    ForEach(Array(devices.availableDevices.enumerated()), id: \.offset) { i in
                        Text(devices.availableDevices[i.offset].name!)
                    }
                }
                Button( action: {
                    devices.fullDisconnect()
                }) {
                    Text("Disconnect")
                }
                .disabled(!devices.hasConnection)
                Button( action: {
                    if devices.hasConnection {
                        devices.logText = ""
                    } else {
                        devices.logText = defaultLogText
                    }
                }) {
                    Text("Clear Log")
                }
            }
            .padding(.leading, 10).padding(.trailing, 10).padding(.top, 5)
            HStack {
                Picker(selection: $presetMessageId, label: Text("Send Message")) {
                    ForEach(0..<supportedCommands.count) { i in
                        Text(supportedCommands[i].description)
                    }
                }
                .onChange(of: presetMessageId) { _ in
                    textFieldDisabled = presetMessageId > 0
                }

                TextField("MIDI Data (e.g., b02743)", text: $customMessage)
                    .disabled(textFieldDisabled)
                Button( action: {
                    devices.processCommand(presetMessageId: presetMessageId, command: customMessage)
                }) {
                    Text("Send")
                }
            }
            .disabled(!devices.hasConnection)
            .padding(10)

        }
    }
}
