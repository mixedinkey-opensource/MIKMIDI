//
//  MIKMIDIResponder.h
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, MIKMIDIResponderType){
	MIKMIDIResponderTypeNone = 0,
	
	MIKMIDIResponderTypeAbsoluteSliderOrKnob = 1 << 0,	/* Absolute position knob or slider */
	MIKMIDIResponderTypeRelativeKnob = 1 << 1,			/* Relative (ie. jog wheel) knob */
	MIKMIDIResponderTypePressButton = 1 << 3,			/* Button that sends message only on press down*/
	MIKMIDIResponderTypePressReleaseButton = 1 << 2,	/* Button that sends message on press down, and another when released*/
	MIKMIDIResponderTypeButton = (MIKMIDIResponderTypePressButton | MIKMIDIResponderTypePressReleaseButton), /* Either kind of button */
	
	MIKMIDIResponderTypeAll = NSUIntegerMax,
};

@class MIKMIDICommand;

@protocol MIKMIDIResponder <NSObject>

@required
- (NSString *)MIDIIdentifier;
- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

@end
