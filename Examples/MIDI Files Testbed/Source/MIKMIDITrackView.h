//
//  MIKMIDITrackView.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIKMIDITrack;

@interface MIKMIDITrackView : NSView

@property (nonatomic, strong) MIKMIDITrack *track;

@end
