//
//  ORSPianoButton.m
//  MIDI Soundboard
//
//  Created by Andrew Madsen on 6/4/13.
//  Copyright (c) 2013 Open Reel Software. All rights reserved.
//

#import "ORSPianoButton.h"

@implementation ORSPianoButton

#pragma mark - MIKMIDIResponder

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command
{
	return NO;
}

- (void)handleMIDICommand:(MIKMIDICommand *)command
{
	NSLog(@"%s %@", __PRETTY_FUNCTION__, command);
}

@end
