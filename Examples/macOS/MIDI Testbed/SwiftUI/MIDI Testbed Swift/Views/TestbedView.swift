//
//  Testbed.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import SwiftUI
import MIKMIDI

struct TestbedView: View {

    @ObservedObject private var deviceSelection = DevicesSelectionViewModel()
    @State private var customMessage: String = ""
    @State private var presetMessage: SupportedCommand = .custom

    var body: some View {

        VStack {
            VStack(alignment: .leading, spacing: nil/*@END_MENU_TOKEN@*/, content: {
                TextView(text: $deviceSelection.logText)
                    .frame(width: 615, height: 390, alignment: .topLeading)
                    .border(Color(red: 0.3, green: 0.3, blue: 0.3))
            })
            .padding(.top, 10)
            HStack {
                Picker(selection: $deviceSelection.selectedIndex, label: Text("Device")) {
                    ForEach(Array(deviceSelection.availableDevices.enumerated()), id: \.offset) { i in
                        Text(deviceSelection.availableDevices[i.offset].name!)
                    }
                }
                Button( action: {
                    deviceSelection.fullDisconnect()
                }) {
                    Text("Disconnect")
                }
                .disabled(!deviceSelection.hasConnection)
                Button( action: {
                    if deviceSelection.hasConnection {
                        deviceSelection.logText = ""
                    } else {
                        deviceSelection.logText = defaultLogText
                    }
                }) {
                    Text("Clear Log")
                }
            }
            .padding(.leading, 10).padding(.trailing, 10).padding(.top, 5)
            HStack {
                Picker(selection: $presetMessage, label: Text("Send Message")) {
                    ForEach(SupportedCommand.all) {
                        Text($0.description).tag($0)
                    }
                }

                TextField("MIDI Data (e.g., b02743)", text: $customMessage)
                    .disabled( presetMessage.command != nil )
                Button(action: {
                    if let presetCommand = presetMessage.command {
                        deviceSelection.send(command: presetCommand)
                    } else {
                        let command = MIKMIDICommand.from(string: customMessage)
                        deviceSelection.send(command: command)
                    }
                }) {
                    Text("Send")
                }
                .disabled( presetMessage.command != nil || customMessage.count < 1 )
            }
            .disabled(!deviceSelection.hasConnection)
            .padding(10)
        }
    }
}

struct TestbedView_Previews: PreviewProvider {
    static var previews: some View {
        TestbedView()
    }
}
