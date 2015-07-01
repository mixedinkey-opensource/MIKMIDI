//
//  MIKMIDISequence+MIKMIDIPrivate.h
//  MIKMIDI
//
//  Created by Chris Flesner on 6/30/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDI.h>

@class MIKMIDISequencer;


@interface MIKMIDISequence (MIKMIDIPrivate)

@property (weak, nonatomic) MIKMIDISequencer *sequencer;

@end
