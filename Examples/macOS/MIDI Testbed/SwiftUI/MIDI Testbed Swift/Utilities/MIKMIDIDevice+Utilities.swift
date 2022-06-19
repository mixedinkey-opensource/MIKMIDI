//
//  MIKMIDIDevice+Utilities.swift
//  Midi Testbed Swift
//
//  Created by Andrew R Madsen on 6/17/22.
//

import Foundation
import MIKMIDI

extension MIKMIDIDevice: Identifiable {
    public var id: MIDIUniqueID { uniqueID }
}
