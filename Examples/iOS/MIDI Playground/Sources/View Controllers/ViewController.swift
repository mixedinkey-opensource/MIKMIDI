//
//  ViewController.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/29/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

class ViewController: UIViewController, MIKMIDIConnectionManagerDelegate {
	
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
			} catch {
				NSLog("Error loading MIDI file: \(error)")
			}
		}
	}
	
	// MARK: Actions
	
	@IBAction func togglePlayback(_ sender: Any) {
		sequencer.isPlaying ? sequencer.stop() : sequencer.resumePlayback()
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
	
	private func deviceSent(commands: [MIKMIDICommand]) {
		previewSynthesizer?.handleMIDIMessages(commands)
		let notes = commands.flatMap { $0 as? MIKMIDINoteCommand }
		for note in notes {
			if note.isNoteOn {
				pianoView.pressDown(key: Int(note.note))
			} else {
				pianoView.liftUp(key: Int(note.note))
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
		
		playingObserver = sequencer.observe(\MIKMIDISequencer.playing, options: [.initial]) { [weak self] (sequencer, change) in
			self?.playButton.title = sequencer.isPlaying ? NSLocalizedString("Pause", comment: "Pause") : NSLocalizedString("Play", comment: "Play")
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowDevices" {
			var vc: DevicesTableViewController!
			if let navVC = segue.destination as? UINavigationController {
				vc = navVC.topViewController as! DevicesTableViewController
			} else {
				vc = segue.destination as! DevicesTableViewController
			}
			
			vc.connectionManager = connectionManager
		}
	}
	
	// MARK: Properties
	
	@IBOutlet var playButton: UIBarButtonItem!
	
	@IBOutlet var sequenceView: MIDISequenceView!
	@IBOutlet var pianoView: PianoView!
	
	private let sequencer = MIKMIDISequencer()
	private var playingObserver: NSKeyValueObservation?
	
	let previewSynthesizer: MIKMIDISynthesizer? = {
		let synth = MIKMIDISynthesizer()
		if let soundfontURL = Bundle.main.url(forResource: "piano", withExtension: "sf2") {
			try? synth?.loadSoundfontFromFile(at: soundfontURL)
		}
		return synth
	}()
	
	private lazy var connectionManager = {
		return MIKMIDIConnectionManager(name: "MIDI Playground", delegate: self) { [weak self] (source, commands) in
			self?.deviceSent(commands: commands)
		}
	}()
	
	private var playheadTimer: Timer? {
		willSet {
			playheadTimer?.invalidate()
		}
	}
}

