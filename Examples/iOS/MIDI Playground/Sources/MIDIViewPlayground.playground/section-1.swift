// Playground - noun: a place where people can play

import UIKit
import MIKMIDI
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

extension UIColor {
	func colorByInterpolating(with otherColor: UIColor, amount: CGFloat) -> UIColor {
		let clampedAmount = min(max(amount, 0.0), 1.0)
		
		guard let startComponent = self.cgColor.components,
			let endComponent = otherColor.cgColor.components else {
				return self
		}
		
		let startAlpha = self.cgColor.alpha
		let endAlpha = otherColor.cgColor.alpha
		
		let r = startComponent[0] + (endComponent[0] - startComponent[0]) * clampedAmount
		let g = startComponent[1] + (endComponent[1] - startComponent[1]) * clampedAmount
		let b = startComponent[2] + (endComponent[2] - startComponent[2]) * clampedAmount
		let a = startAlpha + (endAlpha - startAlpha) * clampedAmount
		
		return UIColor(red: r, green: g, blue: b, alpha: a)
	}
}

class MIDISequenceView : UIView {
	
	// MARK: Drawing
	
	func draw(note: MIKMIDINoteEvent) {
		let yPosition = self.bounds.maxY - CGFloat(note.note) * self.noteHeightInPixels
		let noteRect = CGRect(x: self.bounds.minX + 60.0 + CGFloat(note.timeStamp) * self.pixelsPerTick,
		                      y: yPosition,
		                      width: CGFloat(note.duration) * self.pixelsPerTick,
		                      height: self.noteHeightInPixels)
		
		let path = UIBezierPath(rect: noteRect)
		path.stroke()
		path.fill()
	}
	
	override func draw(_ rect: CGRect) {
	
		UIColor.white.setFill()
		UIBezierPath(rect: self.bounds).fill()
		
		// Draw scale on left
		for note: UInt8 in 0...127 {
			let noteString = MIKMIDINoteLetterAndOctaveForMIDINote(note)
			let font = UIFont(name: "Helvetica", size: 12.0)!
			let attributes = [NSFontAttributeName : font, NSForegroundColorAttributeName : UIColor.black]
			let attrString = NSAttributedString(string: noteString, attributes: attributes)
			let yPosition = self.bounds.maxY - CGFloat(note) * self.noteHeightInPixels
			attrString.draw(at: CGPoint(x: 3.0, y: yPosition))
		}
		UIColor.black.setFill()
		UIBezierPath(rect: CGRect(x: 45.0, y: 0.0, width: 1.0, height: self.bounds.height)).fill()
		
		// Draw notes
		guard let noteTracks = self.noteTracks else { return }
		
		// Draw gridlines
		let maxLength = self.noteTracks!.reduce(0) { (currMax: MusicTimeStamp, track: MIKMIDITrack) -> MusicTimeStamp in
			return max(currMax, track.length);
		}
		UIColor(white: 0.9, alpha: 1.0).setFill()
		for tick in 0...Int(maxLength) {
			UIBezierPath(rect: CGRect(x: 59.0 + CGFloat(tick) * self.pixelsPerTick, y: 0, width: 1.0, height: self.bounds.height)).fill()
		}
		
		// Draw notes
		self.noteHeightInPixels = self.bounds.height / 127.0
		
		for (index, track) in noteTracks.enumerated() {
			let notes = track.events.flatMap { $0 as? MIKMIDINoteEvent }
			for note in notes {
				let noteColor = noteTracks.count == 1 ? self.color(for: note) : self.color(forTrackAt: index)
				noteColor.setFill()
				UIColor.black.setStroke()
				self.draw(note: note)
			}
		}
	}
	
	// MARK: Utilities
	
	func color(for note: MIKMIDINoteEvent) -> UIColor {
		let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
		let noteIndex = Int(note.note) % 12
		let floatIndex = Double(noteIndex) / (Double(12) / Double(colors.count-1))
		let leftColor = colors[Int(floor(floatIndex))]
		let rightColor = colors[Int(ceil(floatIndex))]
		let interpolationAmount = floatIndex - floor(floatIndex)
		return leftColor.colorByInterpolating(with: rightColor, amount: CGFloat(interpolationAmount))
	}
	
	func color(forTrackAt index: Int) -> UIColor {
		let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
		if let numTracks = self.noteTracks?.count {
			let floatIndex = Double(index) / (Double(numTracks) / Double(colors.count-1))
			let leftColor = colors[Int(floor(floatIndex))]
			let rightColor = colors[Int(ceil(floatIndex))]
			let interpolationAmount = floatIndex - floor(floatIndex)
			return leftColor.colorByInterpolating(with: rightColor, amount: CGFloat(interpolationAmount))
		} else {
			return UIColor.gray
		}
	}
	
	// MARK: Properties
	
	var sequence: MIKMIDISequence? {
		didSet {
			let tracks = sequence?.tracks
			self.noteTracks = tracks?.filter {
				$0.events.filter({ $0 is MIKMIDINoteEvent }).count != 0
			}
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
		pixelsPerTick = (self.bounds.width - 60.0) / CGFloat(maxLength)
	}
	var pixelsPerTick : CGFloat = 10.0
	var noteHeightInPixels: CGFloat = 20.0
}

class PianoView: UIView {
	
	// MARK: Drawing
	
	func drawBlack(noteNumber: Int) {
	}
	
	func drawWhite(noteNumber: Int, offset: CGFloat) {
		UIColor.gray.setFill()
		UIBezierPath(rect: CGRect(x: offset+self.whiteKeyWidth, y: 0, width: 1, height: self.bounds.height)).fill()
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.white.setFill()
		UIColor.black.setStroke()
		UIBezierPath(rect: self.bounds).fill()
		UIBezierPath(rect: self.bounds).stroke()
		
		var offset: CGFloat = 0
		UIColor.gray.setFill()
		UIBezierPath(rect: CGRect(x: offset+self.whiteKeyWidth, y: 0, width: 1, height: self.bounds.height)).fill()
		
		let numKeys = self.numberOfKeys
		for noteNumber in 1..<numKeys {
			if noteIsBlack(noteNumber) {
				drawBlack(noteNumber: noteNumber)
			} else {
				drawWhite(noteNumber: noteNumber, offset: offset)
				offset += self.whiteKeyWidth
			}
		}
		
		UIColor.gray.setFill()
		UIBezierPath(rect: CGRect(x: offset+self.whiteKeyWidth, y: 0, width: 1, height: self.bounds.height)).fill()
	}
	
	// MARK: Private Utilities
	
	private func noteIsBlack(_ noteNumber: Int) -> Bool {
		return NSSet(array:[1, 3, 6, 8, 10]).contains((noteNumber % 12));
	}
	
	// MARK: Properties
	
	var isVertical: Bool {
		return self.bounds.width < self.bounds.height
	}
	
	var numberOfKeys: Int = 10 {
		didSet {
			self.setNeedsDisplay()
		}
	}
	
	var whiteKeyWidth: CGFloat {
		let width = self.isVertical ? self.bounds.height : self.bounds.width
		return width / CGFloat(self.numberOfKeys)
	}
}

let pianoView = PianoView(frame: CGRect(x: 0, y: 0, width: 800, height: 100))
PlaygroundPage.current.liveView = pianoView


//let bachURL = NSBundle.mainBundle().URLForResource("bach", withExtension: "mid")YG
//let bachSequence = MIKMIDISequence(fileAtURL: bachURL, error: nil)
//let scaleURL = NSBundle.mainBundle().URLForResource("scale", withExtension: "mid")
//let scaleSequence = MIKMIDISequence(fileAtURL: scaleURL, error: nil)
//
//let sequenceView = MIDISequenceView(frame: CGRect(x: 0, y: 0, width: 800, height: 2000))
//sequenceView.sequence = bachSequence
//XCPShowView("sequenceView", sequenceView)
