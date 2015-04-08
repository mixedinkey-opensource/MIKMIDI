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
	
	var sequenceView: MIDISequenceView {
		get {
			return self.view as! MIDISequenceView
		}
	}

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let sequenceURL = NSBundle.mainBundle().URLForResource("default", withExtension: "mid")
		self.sequenceView.sequence = MIKMIDISequence(fileAtURL: sequenceURL, error: nil)
		
	}
}

