//
//  MIDIFileCollectionViewCell.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/9/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

class MIDIFileCollectionViewCell: UICollectionViewCell {
	
	// MARK: Private
	
	private func updateViews() {
		guard let file = midiFile else {
			sequenceView.sequence = nil
			nameLabel.text = NSLocalizedString("Unknown", comment: "Unknown")
			return
		}
		sequenceView.maxTimeToDisplay = .limited(16)
		sequenceView.drawsGridlines = false
		sequenceView.sequence = file.midiSequence
		nameLabel.text = file.fileURL.deletingPathExtension().lastPathComponent
	}
	
	// MARK: Properties
	
	var midiFile: MIDIFile? {
		didSet {
			updateViews()
		}
	}
	
	@IBOutlet var sequenceView: MIDISequenceView!
	@IBOutlet var nameLabel: UILabel!
}
