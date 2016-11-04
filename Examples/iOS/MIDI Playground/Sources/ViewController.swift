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
        
        if let sequenceURL = Bundle.main.url(forResource: "default", withExtension: "mid") {
            do {
                self.sequenceView.sequence = try MIKMIDISequence(fileAt: sequenceURL)
            } catch {
                NSLog("Error loading MIDI file: \(error)")
            }
        }
    }
}

