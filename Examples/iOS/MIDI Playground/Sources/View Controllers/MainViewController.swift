//
//  MainViewController.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/29/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

class MainViewController: UIViewController, MIKMIDIConnectionManagerDelegate {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		if let sequenceURL = Bundle.main.url(forResource: "default", withExtension: "mid") {
			do {
				sequence = try MIKMIDISequence(fileAt: sequenceURL)
			} catch {
				NSLog("Error loading MIDI file: \(error)")
			}
		}
	}
	
	// MARK: Actions
	
	@IBAction func returnToMainView(_ sender: UIStoryboardSegue) {}
	
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
		let notes = commands.compactMap { $0 as? MIKMIDINoteCommand }
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
		
		playingObserver = sequencer.observe(\MIKMIDISequencer.isPlaying, options: [.initial]) { [weak self] (sequencer, change) in
			if sequencer.isPlaying {
				self?.playButton.title = NSLocalizedString("Pause", comment: "Pause")
				self?.configureDisplayLink()
			} else {
				self?.playButton.title = NSLocalizedString("Play", comment: "Play")
				self?.displayLink = nil
			}
		}
	}
	
	// MARK: Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "ShowDevices" {
			let vc: DevicesTableViewController
			if let navVC = segue.destination as? UINavigationController {
				vc = navVC.topViewController as! DevicesTableViewController
			} else {
				vc = segue.destination as! DevicesTableViewController
			}
			
			vc.connectionManager = connectionManager
		}
	}
	
	// MARK: Display Link
	
	private func configureDisplayLink() {
		let link = CADisplayLink(target: self, selector: #selector(updatePlayhead(_:)))
		link.add(to: .main, forMode: RunLoopMode.defaultRunLoopMode)
		displayLink = link
	}
	
	@objc func updatePlayhead(_ displayLink: CADisplayLink?) {
		sequenceView.playheadTimestamp = sequencer.currentTimeStamp
	}
	
	// MARK: Properties
	
	var sequence: MIKMIDISequence? {
		didSet {
			if let sequence = sequence {
				sequenceView.sequence = sequence
				configureSequencer(sequence)
			} else {
				sequenceView.sequence = nil
			}
		}
	}
	
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
	
	var displayLink: CADisplayLink? {
		willSet {
			displayLink?.invalidate()
		}
	}
}

