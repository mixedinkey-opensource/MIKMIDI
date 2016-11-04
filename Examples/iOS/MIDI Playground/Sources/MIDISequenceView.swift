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
        
        let startComponent = self.cgColor.components
        let endComponent = otherColor.cgColor.components
        
        let startAlpha = self.cgColor.alpha
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
                self.sequence = try MIKMIDISequence(fileAt: midiURL)
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
    
    func drawNote(_ note: MIKMIDINoteEvent) {
        let yPosition = (self.bounds).maxY - CGFloat(note.note) * self.noteHeightInPixels
        let noteRect = CGRect(x: (self.bounds).minX + 60.0 + CGFloat(note.timeStamp) * self.pixelsPerTick,
                              y: yPosition,
                              width: CGFloat(note.duration) * self.pixelsPerTick,
                              height: self.noteHeightInPixels)
        
        let path = UIBezierPath(rect: noteRect)
        path.stroke()
        path.fill()
    }
    
    func drawNotes() {
        self.noteHeightInPixels = self.bounds.height / 127.0
        
        for (index, track) in noteTracks!.enumerated() {
            let events: [MIKMIDINoteEvent] = track.events.filter({ $0 is MIKMIDINoteEvent }) as! [MIKMIDINoteEvent]
            for note in events {
                let noteColor = noteTracks!.count == 1 ? self.colorForNote(note) : self.colorForTrackAtIndex(index)
                noteColor.setFill()
                UIColor.black.setStroke()
                self.drawNote(note)
            }
        }
    }
    
    func drawScale() {
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
    }
    
    func drawGridlines() {
        let maxLength = self.noteTracks!.reduce(0) { (currMax: MusicTimeStamp, track: MIKMIDITrack) -> MusicTimeStamp in
            return max(currMax, track.length);
        }
        UIColor(white: 0.9, alpha: 1.0).setFill()
        for tick in 0...Int(maxLength) {
            UIBezierPath(rect: CGRect(x: 59.0 + CGFloat(tick) * self.pixelsPerTick, y: 0, width: 1.0, height: self.bounds.height)).fill()
        }
    }
    
    override func draw(_ rect: CGRect) {
        
        UIColor.white.setFill()
        UIBezierPath(rect: self.bounds).fill()
        
        // Draw scale on left
        //drawScale();
        
        if self.noteTracks == nil { return }
        
        // Draw gridlines
        drawGridlines();
        // Draw notes
        drawNotes();
    }
    
    // MARK: Utilities
    
    func colorForNote(_ note: MIKMIDINoteEvent) -> UIColor {
        let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
        let noteIndex = Int(note.note) % 12
        let floatIndex = Double(noteIndex) / (Double(12) / Double(colors.count-1))
        let leftColor = colors[Int(floor(floatIndex))]
        let rightColor = colors[Int(ceil(floatIndex))]
        let interpolationAmount = floatIndex - floor(floatIndex)
        return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
    }
    
    func colorForTrackAtIndex(_ index: Int) -> UIColor {
        let colors = [UIColor.red, UIColor.orange, UIColor.yellow, UIColor.green, UIColor.cyan, UIColor.blue]
        if let numTracks = self.noteTracks?.count {
            let floatIndex = Double(index) / (Double(numTracks) / Double(colors.count-1))
            let leftColor = colors[Int(floor(floatIndex))]
            let rightColor = colors[Int(ceil(floatIndex))]
            let interpolationAmount = floatIndex - floor(floatIndex)
            return leftColor.colorByInterpolatingWith(rightColor, amount: CGFloat(interpolationAmount))
        } else {
            return UIColor.gray
        }
    }
    
    // MARK: Properties
    
    var sequence: MIKMIDISequence? {
        didSet {
            let tracks = sequence?.tracks
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
        pixelsPerTick = ((self.bounds).width - 60.0) / CGFloat(maxLength)
    }
    var pixelsPerTick : CGFloat = 10.0
    var noteHeightInPixels: CGFloat = 20.0
}
