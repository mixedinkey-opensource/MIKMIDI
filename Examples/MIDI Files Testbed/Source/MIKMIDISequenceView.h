//
//  MIKMIDITrackView.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIKMIDISequence;

@interface MIKMIDISequenceView : NSView

@property (nonatomic, strong) MIKMIDISequence *sequence;

@end
