//
//  packet.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import CoreMIDI

extension MIDIPacket {
    init(timestamp: MIDITimeStamp, length: Int? = nil, data: Data) {
        let builder = MIDIPacket.Builder(maximumNumberMIDIBytes: length ?? data.count)
        builder.timeStamp = Int(timestamp)
        for byte in data {
            builder.append(byte)
        }

        self = builder.withUnsafePointer { $0.pointee }
    }
}
