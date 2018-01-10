//
//  MIDIFile.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/9/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

import Foundation
import MIKMIDI

struct MIDIFile {
	
	init(fileURL: URL, midiSequence: MIKMIDISequence? = nil) {
		self.fileURL = fileURL
		if let sequence = midiSequence {
			self.midiSequence = sequence
		} else {
			self.midiSequence = try! MIKMIDISequence(fileAt: fileURL)
		}
	}
	
	let fileURL: URL
	let midiSequence: MIKMIDISequence
}
