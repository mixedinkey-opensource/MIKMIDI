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
	MIKMIDIResponderTypeRelativeKnob = 1 << 1,			/* Relative (e.g. Browse) knob */
	MIKMIDIResponderTypeTurntableKnob = 1 << 2,			/* Relative turntable-style knob */
	MIKMIDIResponderTypeRelativeAbsoluteKnob = 1 << 3,	/* Encoder knob that sends absolute-knob-like message */
	MIKMIDIResponderTypePressReleaseButton = 1 << 4,	/* Button that sends message on press down, and another when released*/
	MIKMIDIResponderTypePressButton = 1 << 5,			/* Button that sends message only on press down*/
	
	/* Any kind of knob */
	MIKMIDIResponderTypeKnob = (MIKMIDIResponderTypeAbsoluteSliderOrKnob | MIKMIDIResponderTypeRelativeKnob | \
								MIKMIDIResponderTypeTurntableKnob | MIKMIDIResponderTypeRelativeAbsoluteKnob),
	MIKMIDIResponderTypeButton = (MIKMIDIResponderTypePressButton | MIKMIDIResponderTypePressReleaseButton), /* Either kind of button */
	
	MIKMIDIResponderTypeAll = NSUIntegerMax,
};

@class MIKMIDICommand;

@protocol MIKMIDIResponder <NSObject>

@required
- (NSString *)MIDIIdentifier;
- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

@optional
// Should return a flat (non-recursive) array of subresponders.
// Return nil, empty array, or don't implement if you don't want subresponders to be
// included in any case where the receiver would be considered for receiving MIDI
- (NSArray *)subresponders;

@end
