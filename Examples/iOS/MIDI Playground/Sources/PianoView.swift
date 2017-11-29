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
		numberOfKeys = 128
		numberOfWhiteKeys = 75
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		numberOfKeys = 128
		numberOfWhiteKeys = 75
		super.init(coder: aDecoder)
	}
	
	// MARK: Public
	
	// MARK: Drawing
	
	private func draw(note: Int) {
		var rect = rectForKey(note: note)
		if !noteIsBlack(note) {
			if isVertical {
				rect.size.height = 1
			} else {
				rect.size.width = 1
			}
		}
		UIColor.black.setFill()
		UIBezierPath(rect: rect).fill()
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.white.setFill()
		UIColor.black.setStroke()
		UIBezierPath(rect: bounds).fill()
		UIBezierPath(rect: bounds).stroke()
		
		Array(0..<numberOfKeys).forEach(draw)
	}
	
	// MARK: Private Utilities
	
	private func noteIsBlack(_ noteNumber: Int) -> Bool {
		return [1, 3, 6, 8, 10].contains(noteNumber % 12);
	}
	
	private func rectForKey(note: Int) -> CGRect {
		var keyWidth = whiteKeyWidth
		var keyHeight = isVertical ? bounds.width : bounds.height
		if noteIsBlack(note) {
			keyWidth *= 0.7
			keyHeight *= 0.6
		}
		
		let whiteNotes = Array(0..<note).filter { !noteIsBlack($0) }
		let offset = CGFloat(whiteNotes.count) * whiteKeyWidth
		
		var rect = CGRect.zero
		if isVertical {
			rect = CGRect(x: 0, y: offset + keyWidth, width: keyHeight, height: keyWidth)
		} else {
			rect = CGRect(x: offset + keyWidth, y: 0, width: keyWidth, height: keyHeight)
		}
		return rect.integral
	}
	
	// MARK: Properties
	
	var isVertical: Bool {
		return bounds.width < bounds.height
	}
	
	@IBInspectable var numberOfKeys: Int {
		didSet {
			let blackKeys = Array(0..<numberOfKeys).filter(noteIsBlack)
			numberOfWhiteKeys = numberOfKeys - blackKeys.count
			
			setNeedsDisplay()
		}
	}
	
	var numberOfWhiteKeys: Int
	
	var whiteKeyWidth: CGFloat {
		let width = isVertical ? bounds.height : bounds.width
		return width / CGFloat(numberOfWhiteKeys)
	}
}
