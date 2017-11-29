//
//  NoteTap.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 11/29/17.
//  Copyright © 2017 Mixed In Key. All rights reserved.
//

import Foundation
import MIKMIDI

typealias MessageHandler = ([MIKMIDICommand]) -> ()

class NoteTap: NSObject, MIKMIDICommandScheduler {
	
	init(destinationScheduler: MIKMIDICommandScheduler, messageHandler: @escaping MessageHandler) {
		self.destinationScheduler = destinationScheduler
		self.messageHandler = messageHandler
	}
	
	func scheduleMIDICommands(_ commands: [MIKMIDICommand]) {
		self.destinationScheduler.scheduleMIDICommands(commands)
		self.messageHandler(commands)
	}
	
	// MARK: Properties
	
	let destinationScheduler: MIKMIDICommandScheduler
	private let messageHandler: MessageHandler
}
