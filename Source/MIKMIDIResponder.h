//
//  MIKMIDIResponder.h
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, MIKMIDIResponderType){
	MIKMIDIResponderTypeAbsoluteSliderOrKnob = 1 << 0,	/* Absolute position knob or slider */
	MIKMIDIResponderTypeRelativeKnob = 1 << 1,			/* Relative (ie. jog wheel) knob */
	MIKMIDIResponderTypeButton = 1 << 2,				/* Button */
	
	MIKMIDIResponderTypeAll = NSUIntegerMax,
};

@class MIKMIDICommand;

@protocol MIKMIDIResponder <NSObject>

@required
- (NSString *)MIDIIdentifier;
- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

@optional
- (MIKMIDIResponderType)MIDIResponderType; // Optional. If not implemented, only MIKMIDIResponderTypeAll will be assumed.

@end
