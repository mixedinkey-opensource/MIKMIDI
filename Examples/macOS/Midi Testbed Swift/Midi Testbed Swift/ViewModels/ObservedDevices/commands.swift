//
//  commands.swift
//  Midi Testbed Swift
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI

struct supportedCommand {
    var Description: String
    var Command: MIKMIDICommand?
}

// supportedCommands is the list of commands available in the UI drop-down list
let supportedCommands: [supportedCommand] = [
    supportedCommand(Description: "Custom Message",
                     Command: nil),
    supportedCommand(Description: "Identity Request",
                     Command: MIKMIDISystemExclusiveCommand.identityRequest())
]
