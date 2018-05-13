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
    func colorByInterpolatingWith(_ otherColor: UIColor, amount: CGFloat) -> UIColor {
        var amount = amount
        amount = min(max(amount, 0.0), 1.0)
        
        let startComponent = cgColor.components
        let endComponent = otherColor.cgColor.components
        
        let startAlpha = cgColor.alpha
        let endAlpha = otherColor.cgColor.alpha
        
        let r = (startComponent?[0])! + ((endComponent?[0])! - (startComponent?[0])!) * amount
        let g = (startComponent?[1])! + ((endComponent?[1])! - (startComponent?[1])!) * amount
        let b = (startComponent?[2])! + ((endComponent?[2])! - (startComponent?[2])!) * amount
        let a = startAlpha + (endAlpha - startAlpha) * amount
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

@IBDesignable class MIDISequenceView : UIView {
    
    override func prepareForInterfaceBuilder() {
        let bundle = Bundle(for: type(of: self))
        if let midiURL = bundle.url(forResource: "default", withExtension: "mid") {
            do {
                sequence = try MIKMIDISequence(fileAt: midiURL)
            } catch {
                NSLog("Error loading MIDI file: \(error)")
            }
        } else {
            let sequence = MIKMIDISequence()
            if let track = try? sequence.addTrack() {
                
                var timestamp: MusicTimeStamp = 0
                for note in 60...72 {
                    track.addEvent(MIKMIDINoteEvent(timeStamp: timestamp, note: UInt8(note), velocity:UInt8(127), duration: Float32(1.0), channel: UInt8(0)))
                    timestamp += 1
                }
            }
            
            self.sequence = sequence
        }
    }
    
    // MARK: Drawing
    
    private func draw(note: MIKMIDINoteEvent, dirtyRect: CGRect? = nil) {
        let dirtyRect = (dirtyRect ?? bounds).insetBy(dx: -2.0, dy: -2.0)
		
		let noteRect = rect(for: note)
        if !noteRect.intersects(dirtyRect) { return }
        
        let path = UIBezierPath(rect: noteRect.insetBy(dx: 0, dy: 1.0))
		path.lineWidth = 2.0
        path.stroke()
        path.fill()
    }
    
    private func drawNotes(_ dirtyRect: CGRect? = nil) {
        let dirtyRect = dirtyRect ?? bounds
		
		let whiteNotes = Array(minNote..<maxNote).filter { !noteIsBlack($0) }
        noteHeightInPixels = bounds.height / CGFloat(whiteNotes.count)
		
		UIColor.black.setStroke()
        for (index, track) in noteTracks!.enumerated() {
			var notes = track.events.compactMap { $0 as? MIKMIDINoteEvent }
			if case .limited(let limitedWidth) = maxTimeToDisplay {
				notes = notes.filter { $0.timeStamp <= limitedWidth }
			}
            for note in notes {
                let noteColor = noteTracks!.count == 1 ? colorForNote(note) : colorForTrackAtIndex(index)
                noteColor.setFill()
                draw(note: note, dirtyRect: dirtyRect)
            }
        }
    }
    
    private func drawGridlines() {
		var maxLength = noteTracks?.map({ $0.length }).max(by: <) ?? 0
		if case .limited(let limitedWidth) = maxTimeToDisplay {
			maxLength = min(maxLength, limitedWidth)
		}
        UIColor(white: 0.9, alpha: 1.0).setFill()
        for tick in 0...Int(maxLength) {
            UIBezierPath(rect: CGRect(x: CGFloat(tick) * pixelsPerTick, y: 0, width: 1.0, height: bounds.height)).fill()
        }
    }
    
    private func drawPlayhead(_ dirtyRect: CGRect? = nil) {
        guard let timestamp = playheadTimestamp else { return }
        let dirtyRect = dirtyRect ?? bounds
        
        let rect = rectFor(playheadAt: timestamp)
        if !rect.intersects(dirtyRect) { return }
        
        UIColor.red.setFill()
        UIBezierPath(rect: rect).fill()
    }
    
    override func draw(_ rect: CGRect) {
        
        UIColor.white.setFill()
        UIBezierPath(rect: bounds).fill()
        
        if noteTracks == nil { return }
        
        // Draw gridlines
		if drawsGridlines { drawGridlines() }
        // Draw notes
        drawNotes(rect)
        // Draw playhead
        drawPlayhead(rect)
    }
    
    // MARK: Utilities
    
    private func colorForNote(_ note: MIKMIDINoteEvent) -> UIColor {
        let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
        let noteIndex = Int(note.note) % 12
        let floatIndex = Double(noteIndex) / (Double(12) / Double(colors.count-1))
        let leftColor = colors[Int(floor(floatIndex))]
        let rightColor = colors[Int(ceil(floatIndex))]
        let interpolationAmount = floatIndex - floor(floatIndex)
        return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
    }
    
    private func colorForTrackAtIndex(_ index: Int) -> UIColor {
        let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
        if let numTracks = noteTracks?.count {
            let floatIndex = Double(index) / (Double(numTracks) / Double(colors.count-1))
            let leftColor = colors[Int(floor(floatIndex))]
            let rightColor = colors[Int(ceil(floatIndex))]
            let interpolationAmount = floatIndex - floor(floatIndex)
            return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
        } else {
            return UIColor.gray
        }
    }
	
	private func noteIsBlack(_ noteNumber: Int) -> Bool {
		return [1, 3, 6, 8, 10].contains(noteNumber % 12);
	}
	
	private func rect(for noteEvent: MIKMIDINoteEvent) -> CGRect {
		let note = Int(noteEvent.note)
		if note < minNote || note > maxNote { return .zero } // Note is out of bounds
		
		let whiteNotes = Array(minNote..<note).filter { !noteIsBlack($0) }
		var offset = CGFloat(whiteNotes.count) * noteHeightInPixels
		if noteIsBlack(note) { offset -= noteHeightInPixels / 2.0 }
		
		let width = CGFloat(noteEvent.duration) * pixelsPerTick
		let rect = CGRect(x: bounds.minX + CGFloat(noteEvent.timeStamp) * pixelsPerTick,
						  y: bounds.maxY - offset - noteHeightInPixels,
						  width: width,
						  height: noteHeightInPixels)
		return rect.integral
	}
	
    private func rectFor(playheadAt timestamp: MusicTimeStamp) -> CGRect {
        let position = bounds.minX + CGFloat(timestamp) * pixelsPerTick
        return CGRect(x: position, y: 0, width: 2.0, height: bounds.height)
    }
    
    // MARK: Properties
	
	enum TimeWidth {
		case all
		case limited(MusicTimeStamp)
	}
	
	var maxTimeToDisplay = TimeWidth.all {
		didSet {
			calculatePixelsPerTick()
			setNeedsDisplay()
		}
	}
	
	var drawsGridlines = true {
		didSet {
			setNeedsDisplay()
		}
	}
    
    var sequence: MIKMIDISequence? {
        didSet {
            let tracks = sequence?.tracks
            noteTracks = tracks?.filter({ (track: MIKMIDITrack) -> Bool in
                return track.events.filter({ $0 is MIKMIDINoteEvent }).count != 0
            })
            calculatePixelsPerTick()
            setNeedsDisplay()
        }
    }
    var noteTracks: [MIKMIDITrack]?
    
    var playheadTimestamp: MusicTimeStamp? {
        willSet {
            if let timestamp = playheadTimestamp, timestamp != newValue {
                setNeedsDisplay(rectFor(playheadAt: timestamp))
            }
        }
        didSet {
            if let timestamp = playheadTimestamp, timestamp != oldValue {
                setNeedsDisplay(rectFor(playheadAt: timestamp))
            }
        }
    }
	
	@IBInspectable var minNote: Int = 0 {
		didSet {
			setNeedsDisplay()
		}
	}
	@IBInspectable var maxNote: Int = 128 {
		didSet {
			setNeedsDisplay()
		}
	}
	var numberOfNotes: Int { return maxNote - minNote }
    
    private func calculatePixelsPerTick () {
        guard let noteTracks = noteTracks else {
            pixelsPerTick = 10.0
            return
        }
        
		var maxLength = noteTracks.map({ $0.length }).max(by: <) ?? 0
		if case .limited(let limitedWidth) = maxTimeToDisplay {
			maxLength = min(maxLength, limitedWidth)
		}
        pixelsPerTick = bounds.width / CGFloat(maxLength)
    }
    private var pixelsPerTick : CGFloat = 10.0
    private var noteHeightInPixels: CGFloat = 20.0
}
