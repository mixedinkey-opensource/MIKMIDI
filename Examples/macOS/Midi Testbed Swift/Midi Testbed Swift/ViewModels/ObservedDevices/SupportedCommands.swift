//
//  Commands.swift
//  Midi Testbed Swift
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI

struct SupportedCommand: CustomStringConvertible {
    var description: String
    var command: MIKMIDICommand?
}

// supportedCommands is the list of commands available in the UI drop-down list
let supportedCommands: [SupportedCommand] = [
    SupportedCommand(description: "Custom Message",
                     command: nil),
    SupportedCommand(description: "Identity Request",
                     command: MIKMIDISystemExclusiveCommand.identityRequest())
]
