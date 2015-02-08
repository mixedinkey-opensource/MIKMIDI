//
//  MIDISequenceView.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 1/29/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit
import MIKMIDI

extension UIColor {
	func colorByInterpolatingWith(otherColor: UIColor, var amount: CGFloat) -> UIColor {
		amount = min(max(amount, 0.0), 1.0)
		
		let startComponent = CGColorGetComponents(self.CGColor)
		let endComponent = CGColorGetComponents(otherColor.CGColor)
		
		let startAlpha = CGColorGetAlpha(self.CGColor)
		let endAlpha = CGColorGetAlpha(otherColor.CGColor)
		
		let r = startComponent[0] + (endComponent[0] - startComponent[0]) * amount
		let g = startComponent[1] + (endComponent[1] - startComponent[1]) * amount
		let b = startComponent[2] + (endComponent[2] - startComponent[2]) * amount
		let a = startAlpha + (endAlpha - startAlpha) * amount
		
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

class MIDISequenceView : UIView {
	
	// MARK: Drawing
	
	func drawNote(note: MIKMIDINoteEvent) {
		let yPosition = CGRectGetMaxY(self.bounds) - CGFloat(note.note) * self.noteHeightInPixels
		let noteRect = CGRectMake(CGRectGetMinX(self.bounds) + 60.0 + CGFloat(note.timeStamp) * self.pixelsPerTick,
			yPosition,
			CGFloat(note.duration) * self.pixelsPerTick,
			self.noteHeightInPixels)
		
		let path = UIBezierPath(rect: noteRect)
		path.stroke()
		path.fill()
	}
	
	func drawNotes() {
		self.noteHeightInPixels = CGRectGetHeight(self.bounds) / 127.0
		
		for (index, track) in enumerate(noteTracks!) {
			let events: [MIKMIDINoteEvent] = track.events.filter({ $0 is MIKMIDINoteEvent }) as [MIKMIDINoteEvent]
			for note in events {
				let noteColor = noteTracks!.count == 1 ? self.colorForNote(note) : self.colorForTrackAtIndex(index)
				noteColor.setFill()
				UIColor.blackColor().setStroke()
				self.drawNote(note)
			}
		}
	}
	
	func drawScale() {
		for note: UInt8 in 0...127 {
			let noteString = MIKMIDINoteLetterAndOctaveForMIDINote(note)
			let font = UIFont(name: "Helvetica", size: 12.0)!
			let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.blackColor()]
			let attrString = NSAttributedString(string: noteString, attributes: attributes)
			let yPosition = CGRectGetMaxY(self.bounds) - CGFloat(note) * self.noteHeightInPixels
			attrString.drawAtPoint(CGPointMake(3.0, yPosition))
		}
		UIColor.blackColor().setFill()
		UIBezierPath(rect: CGRectMake(45.0, 0.0, 1.0, CGRectGetHeight(self.bounds))).fill()
	}
	
	func drawGridlines() {
		let maxLength = self.noteTracks!.reduce(0) { (currMax: MusicTimeStamp, track: MIKMIDITrack) -> MusicTimeStamp in
			return max(currMax, track.length);
		}
		UIColor(white: 0.9, alpha: 1.0).setFill()
		for tick in 0...Int(maxLength) {
			UIBezierPath(rect: CGRectMake(59.0 + CGFloat(tick) * self.pixelsPerTick, 0, 1.0, CGRectGetHeight(self.bounds))).fill()
		}
	}
	
	override func drawRect(rect: CGRect) {
		
		UIColor.whiteColor().setFill()
		UIBezierPath(rect: self.bounds).fill()
		
		// Draw scale on left
		drawScale();
		
		if self.noteTracks == nil { return }
		
		// Draw gridlines
		drawGridlines();
		// Draw notes
		drawNotes();
	}
	
	// MARK: Utilities
	
	func colorForNote(note: MIKMIDINoteEvent) -> UIColor {
		let colors = [UIColor.redColor(), UIColor.orangeColor(), UIColor.yellowColor(), UIColor.greenColor(), UIColor.cyanColor(), UIColor.blueColor()]
		let noteIndex = Int(note.note) % 12
		let floatIndex = Double(noteIndex) / (Double(12) / Double(colors.count-1))
		let leftColor = colors[Int(floor(floatIndex))]
		let rightColor = colors[Int(ceil(floatIndex))]
		let interpolationAmount = floatIndex - floor(floatIndex)
		return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
	}
	
	func colorForTrackAtIndex(index: Int) -> UIColor {
		let colors = [UIColor.redColor(), UIColor.orangeColor(), UIColor.yellowColor(), UIColor.greenColor(), UIColor.cyanColor(), UIColor.blueColor()]
		if let numTracks = self.noteTracks?.count {
			let floatIndex = Double(index) / (Double(numTracks) / Double(colors.count-1))
			let leftColor = colors[Int(floor(floatIndex))]
			let rightColor = colors[Int(ceil(floatIndex))]
			let interpolationAmount = floatIndex - floor(floatIndex)
			return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
		} else {
			return UIColor.grayColor()
		}
	}
	
	// MARK: Properties
	
	var sequence: MIKMIDISequence? {
		didSet {
			let tracks = sequence?.tracks as? [MIKMIDITrack]
			self.noteTracks = tracks?.filter({ (track: MIKMIDITrack) -> Bool in
				return track.events.filter({ $0 is MIKMIDINoteEvent }).count != 0
			})
			self.calculatePixelsPerTick()
			self.setNeedsDisplay()
		}
	}
	var noteTracks: [MIKMIDITrack]?
	
	func calculatePixelsPerTick () {
		if (self.noteTracks == nil) {
			pixelsPerTick = 10.0
			return
		}
		
		let maxLength = self.noteTracks!.reduce(0) { (currMax: MusicTimeStamp, track: MIKMIDITrack) -> MusicTimeStamp in
			return max(currMax, track.length);
		}
		pixelsPerTick = (CGRectGetWidth(self.bounds) - 60.0) / CGFloat(maxLength)
	}
	var pixelsPerTick : CGFloat = 10.0
	var noteHeightInPixels: CGFloat = 20.0
}