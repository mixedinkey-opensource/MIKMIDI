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
	
	required init(coder aDecoder: NSCoder) {
		self.numberOfKeys = 128
		self.numberOfBlackKeys = 53
		self.numberOfWhiteKeys = 75
		super.init(coder: aDecoder)
	}
	
	// MARK: Drawing
	
	func drawBlackNote(var offset: CGFloat) {
		let keyWidth = self.whiteKeyWidth * 0.7
		
		var rect = CGRectZero
		if self.isVertical {
			rect = CGRectIntegral(CGRectMake(0, offset + keyWidth, CGRectGetWidth(self.bounds) * 0.6, keyWidth))
		} else {
			rect = CGRectIntegral(CGRectMake(offset + keyWidth, 0, keyWidth, CGRectGetHeight(self.bounds) * 0.6))
		}
		
		UIColor.blackColor().setFill()
		UIBezierPath(rect: rect).fill()
	}
	
	func drawWhiteNote(offset: CGFloat) {
		
		var rect = CGRectZero
		if self.isVertical {
			rect = CGRectIntegral(CGRectMake(0, offset, CGRectGetWidth(self.bounds), 1))
		} else {
			rect = CGRectIntegral(CGRectMake(offset, 0, 1, CGRectGetHeight(self.bounds)))
		}
		
		UIColor.lightGrayColor().setFill()
		UIBezierPath(rect: rect).fill()
	}
	
	override func drawRect(rect: CGRect) {
		UIColor.whiteColor().setFill()
		UIColor.blackColor().setStroke()
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
	
	private func noteIsBlack(noteNumber: Int) -> Bool {
		return NSSet(array:[1, 3, 6, 8, 10]).containsObject((noteNumber % 12));
	}
	
	// MARK: Properties
	
	var isVertical: Bool {
		return CGRectGetWidth(self.bounds) < CGRectGetHeight(self.bounds)
	}
	
	@IBInspectable var numberOfKeys: Int {
		didSet {
			var numBlackKeys = 0
			for index in 0..<numberOfKeys {
				if noteIsBlack(index) {
					numBlackKeys++
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
		let width = self.isVertical ? CGRectGetHeight(self.bounds) : CGRectGetWidth(self.bounds)
		return width / CGFloat(self.numberOfWhiteKeys)
	}
}