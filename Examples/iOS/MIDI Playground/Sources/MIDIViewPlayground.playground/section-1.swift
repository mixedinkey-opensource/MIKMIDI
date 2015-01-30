// Playground - noun: a place where people can play

import UIKit
import MIKMIDI
import XCPlayground

class MIDISequenceView : UIView {

	var sequence: MIKMIDISequence? {
		didSet {
			self.setNeedsDisplay()
		}
	}

	var pixelsPerTick : CGFloat {
		if (self.sequence == nil) { return 10.0 }

		let tracks = self.sequence!.tracks as [MIKMIDITrack]
		let maxLength = tracks.reduce(0) { (currMax: MusicTimeStamp, track: MIKMIDITrack) -> MusicTimeStamp in
			return max(currMax, track.length);
		}
		return CGRectGetWidth(self.bounds) / CGFloat(maxLength)
	}

	var pixelsPerNote : CGFloat {
		return CGRectGetHeight(self.bounds) / 127.0
	}
	
	func drawNote(note: MIKMIDINoteEvent) {
		let yPosition = CGRectGetMaxY(self.bounds) - CGFloat(note.note) * self.pixelsPerNote
		let noteRect = CGRectMake(CGRectGetMinX(self.bounds) + CGFloat(note.timeStamp) * self.pixelsPerTick,
			yPosition,
			CGFloat(note.duration) * self.pixelsPerTick,
			self.pixelsPerNote)
		
		let path = UIBezierPath(rect: noteRect)
		path.stroke()
		path.fill()
	}

	override func drawRect(rect: CGRect) {
		
		UIColor.whiteColor().setFill()
		UIBezierPath(rect: rect).fill()
		
		if self.sequence == nil { return }

		let ppt = self.pixelsPerTick
		let noteHeight = self.pixelsPerNote

		let tracks = self.sequence!.tracks as [MIKMIDITrack]
		for (index, track) in enumerate(tracks) {
			let events = track.events as [MIKMIDIEvent]
			for event in events {
				if let note = event as? MIKMIDINoteEvent {
//					let noteColor = tracks.count <= 2 ? self.colorForNote(note) : self.colorForTrackAtIndex(index)
					UIColor.blackColor().setStroke()
					self.colorForNote(note).setFill()
					self.drawNote(note)
				}

			}
		}
	}

	func colorForNote(note: MIKMIDINoteEvent) -> UIColor {
		let colors = [UIColor.redColor(), UIColor.orangeColor(), UIColor.yellowColor(), UIColor.greenColor(), UIColor.cyanColor(), UIColor.blueColor()]
		let noteIndex = (Int(note.note) % 12)
		println("\(note.note) -> \(noteIndex)")
		return colors[noteIndex / 2]
	}

	func colorForTrackAtIndex(index: Int) -> UIColor {
		let colors = [UIColor.redColor(), UIColor.orangeColor(), UIColor.yellowColor(), UIColor.greenColor(), UIColor.blueColor(), UIColor.purpleColor()]
		return colors.first!
	}
}

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

let sequenceURL = NSBundle.mainBundle().URLForResource("scale", withExtension: "mid")
let sequence = MIKMIDISequence(fileAtURL: sequenceURL, error: nil)

let sequenceView = MIDISequenceView(frame: CGRectMake(0, 0, 600, 200))
sequenceView.sequence = sequence
XCPShowView("sequenceView", sequenceView)
