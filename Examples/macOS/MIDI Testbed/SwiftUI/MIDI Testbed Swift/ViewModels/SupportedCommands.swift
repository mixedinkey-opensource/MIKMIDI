//
//  Commands.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import MIKMIDI

struct SupportedCommand: CustomStringConvertible, Identifiable, Hashable {

    static let all: [SupportedCommand] = [
        custom,
        SupportedCommand(description: "Identity Request",
                         command: MIKMIDISystemExclusiveCommand.identityRequest())
    ]

    static let custom = SupportedCommand(description: "Custom Message", command: nil)

    var description: String
    var command: MIKMIDICommand?
    var id = UUID()
}
