//
//  ViewController.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/29/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

class ViewController: UIViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let sequenceURL = Bundle.main.url(forResource: "default", withExtension: "mid") {
			do {
				let sequence = try MIKMIDISequence(fileAt: sequenceURL)
				sequenceView.sequence = sequence
				configureSequencer(sequence)
				playheadTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
					self?.sequenceView.playheadTimestamp = self?.sequencer.currentTimeStamp
				}
				sequencer.startPlayback()
			} catch {
				NSLog("Error loading MIDI file: \(error)")
			}
		}
	}
	
	// MARK: Private
	
	private func commandWasScheduled(command: MIKMIDICommand) {
		DispatchQueue.main.async {
			if let noteOn = command as? MIKMIDINoteOnCommand {
				self.pianoView.pressDown(key: Int(noteOn.note))
			} else if let noteOff = command as? MIKMIDINoteOffCommand {
				self.pianoView.liftUp(key: Int(noteOff.note))
			}
		}
	}
	
	private func configureSequencer(_ sequence: MIKMIDISequence) {
		sequencer.sequence = sequence
		if let soundfontURL = Bundle.main.url(forResource: "piano", withExtension: "sf2") {
			for track in sequence.tracks {
				let synth = sequencer.builtinSynthesizer(for: track)
				try? synth?.loadSoundfontFromFile(at: soundfontURL)
			}
		}
		
		for track in sequence.tracks {
			if let scheduler = sequencer.commandScheduler(for: track) {
				let noteTap = NoteTap(destinationScheduler: scheduler, messageHandler: { [weak self] (commands) in
					for command in commands { self?.commandWasScheduled(command: command) }
				})
				sequencer.setCommandScheduler(noteTap, for: track)
			}
		}
	}
	
	// MARK: Properties
	
	private var sequenceView: MIDISequenceView {
		get {
			return self.view as! MIDISequenceView
		}
	}
	
	@IBOutlet var pianoView: PianoView!
	
	private let sequencer = MIKMIDISequencer()
	
	private var playheadTimer: Timer? {
		willSet {
			playheadTimer?.invalidate()
		}
	}
}

