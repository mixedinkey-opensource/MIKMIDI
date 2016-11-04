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
		self.numberOfKeys = 128
		self.numberOfBlackKeys = 53
		self.numberOfWhiteKeys = 75
		super.init(frame: frame)
	}
	
	required init?(coder aDecoder: NSCoder) {
		self.numberOfKeys = 128
		self.numberOfBlackKeys = 53
		self.numberOfWhiteKeys = 75
		super.init(coder: aDecoder)
	}
	
	// MARK: Drawing
	
	func drawBlackNote(_ offset: CGFloat) {
		let offset = offset
		let keyWidth = self.whiteKeyWidth * 0.7
		
		var rect = CGRect.zero
		if self.isVertical {
			rect = CGRect(x: 0, y: offset + keyWidth, width: self.bounds.width * 0.6, height: keyWidth).integral
		} else {
			rect = CGRect(x: offset + keyWidth, y: 0, width: keyWidth, height: self.bounds.height * 0.6).integral
		}
		
		UIColor.black.setFill()
		UIBezierPath(rect: rect).fill()
	}
	
	func drawWhiteNote(_ offset: CGFloat) {
		
		var rect = CGRect.zero
		if self.isVertical {
			rect = CGRect(x: 0, y: offset, width: self.bounds.width, height: 1).integral
		} else {
			rect = CGRect(x: offset, y: 0, width: 1, height: self.bounds.height).integral
		}
		
		UIColor.lightGray.setFill()
		UIBezierPath(rect: rect).fill()
	}
	
	override func draw(_ rect: CGRect) {
		UIColor.white.setFill()
		UIColor.black.setStroke()
		UIBezierPath(rect: self.bounds).fill()
		UIBezierPath(rect: self.bounds).stroke()
		
		var offset: CGFloat = 0
		
//		UIColor.grayColor().setFill()
//		UIBezierPath(rect: CGRectMake(offset+self.whiteKeyWidth, 0, 1, CGRectGetHeight(self.bounds))).fill()
		
		let numKeys = self.numberOfKeys
		for noteNumber in 0..<numKeys {
			if !noteIsBlack(noteNumber) {
				drawWhiteNote(offset)
				offset += self.whiteKeyWidth
			}
		}
		
		offset = 0
		for noteNumber in 0..<numKeys {
			if (noteIsBlack(noteNumber)) {
				drawBlackNote(offset)
			} else {
				offset += self.whiteKeyWidth
			}
		}
		
//		UIColor.grayColor().setFill()
//		UIBezierPath(rect: CGRectMake(offset+self.whiteKeyWidth, 0, 1, CGRectGetHeight(self.bounds))).fill()
	}
	
	// MARK: Private Utilities
	
	fileprivate func noteIsBlack(_ noteNumber: Int) -> Bool {
		return NSSet(array:[1, 3, 6, 8, 10]).contains((noteNumber % 12));
	}
	
	// MARK: Properties
	
	var isVertical: Bool {
		return self.bounds.width < self.bounds.height
	}
	
	@IBInspectable var numberOfKeys: Int {
		didSet {
			var numBlackKeys = 0
			for index in 0..<numberOfKeys {
				if noteIsBlack(index) {
					numBlackKeys += 1
				}
			}
			
			self.numberOfBlackKeys = numBlackKeys
			self.numberOfWhiteKeys = numberOfKeys - numBlackKeys
			
			self.setNeedsDisplay()
		}
	}
	
	var numberOfWhiteKeys: Int
	var numberOfBlackKeys: Int
	
	var whiteKeyWidth: CGFloat {
		let width = self.isVertical ? self.bounds.height : self.bounds.width
		return width / CGFloat(self.numberOfWhiteKeys)
	}
}
