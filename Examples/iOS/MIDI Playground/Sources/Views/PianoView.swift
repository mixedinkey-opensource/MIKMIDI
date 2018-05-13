//
//  PianoView.swift
//  MIDI Playground
//
//  Created by Andrew Madsen on 2/7/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

import UIKit

@IBDesignable class PianoView: UIView {
	
	override init(frame: CGRect) {
		numberOfWhiteKeys = 75
		super.init(frame: frame)
		isVertical = bounds.width < bounds.height
	}
	
	required init?(coder aDecoder: NSCoder) {
		numberOfWhiteKeys = 75
		super.init(coder: aDecoder)
		isVertical = bounds.width < bounds.height
	}
	
	// MARK: Public
	
	private var pressedKeys = Set<Int>() {
		didSet {
			let changed = pressedKeys.union(oldValue).subtracting(pressedKeys.intersection(oldValue))
			for key in changed {
				setNeedsDisplay(rectForKey(note: key))
			}
		}
	}
	
	func pressDown(key: Int) {
		pressedKeys.insert(key)
	}
	
	func liftUp(key: Int) {
		pressedKeys.remove(key)
	}
	
	// MARK: Drawing
	
	private func draw(note: Int, dirtyRect: CGRect) {
		let isPressedDown = pressedKeys.contains(note)
		var rect = rectForKey(note: note)
		if !noteIsBlack(note) && !isPressedDown {
			if isVertical {
				rect.size.height = 1
			} else {
				rect.size.width = 1
			}
		}
		
		if rect.intersects(dirtyRect) {
		let color: UIColor = isPressedDown ? .gray : .black
		color.setFill()
		UIBezierPath(rect: rect).fill()
		}
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.white.setFill()
		UIColor.black.setStroke()
		UIBezierPath(rect: rect).fill()
		UIBezierPath(rect: rect).stroke()
		
		let allKeys = Array(minNote..<maxNote)
		let whiteKeys = allKeys.filter { !noteIsBlack($0) }
		let blackKeys = allKeys.filter { noteIsBlack($0) }
		for key in whiteKeys { draw(note: key, dirtyRect: rect) }
		for key in blackKeys { draw(note: key, dirtyRect: rect) }
	}
	
	// MARK: Private Utilities
	
	private func noteIsBlack(_ noteNumber: Int) -> Bool {
		return [1, 3, 6, 8, 10].contains(noteNumber % 12);
	}
	
	private func rectForKey(note: Int) -> CGRect {
		
		if note < minNote || note > maxNote { return .zero } // Note is out of bounds
		
		var keyWidth = whiteKeyWidth
		var keyHeight = isVertical ? bounds.width : bounds.height
		if noteIsBlack(note) {
			keyWidth *= 0.7
			keyHeight *= 0.6
		}
		
		var whiteNotesCount = 0
		for n in minNote..<note {
			if !noteIsBlack(n) { whiteNotesCount += 1 }
		}
		var offset = CGFloat(whiteNotesCount) * whiteKeyWidth
		if noteIsBlack(note) { offset -= keyWidth / 2.0 }
		
		var rect = CGRect.zero
		if isVertical {
			rect = CGRect(x: 0, y: bounds.maxY-offset - keyWidth, width: keyHeight, height: keyWidth)
		} else {
			rect = CGRect(x: bounds.maxY-offset - keyWidth, y: 0, width: keyWidth, height: keyHeight)
		}
		return rect.integral
	}
	
	// MARK: Properties
	
	override var bounds: CGRect {
		didSet {
			isVertical = bounds.width < bounds.height
		}
	}
	
	var isVertical: Bool = false
	
	@IBInspectable var minNote: Int = 0 {
		didSet {
			let blackKeys = Array(minNote..<maxNote).filter(noteIsBlack)
			numberOfWhiteKeys = numberOfNotes - blackKeys.count
			setNeedsDisplay()
		}
	}
	@IBInspectable var maxNote: Int = 128 {
		didSet {
			let blackKeys = Array(minNote..<maxNote).filter(noteIsBlack)
			numberOfWhiteKeys = numberOfNotes - blackKeys.count
			setNeedsDisplay()
		}
	}
	var numberOfNotes: Int { return maxNote - minNote }
	
	var numberOfWhiteKeys: Int
	
	var whiteKeyWidth: CGFloat {
		let width = isVertical ? bounds.height : bounds.width
		return width / CGFloat(numberOfWhiteKeys)
	}
}
