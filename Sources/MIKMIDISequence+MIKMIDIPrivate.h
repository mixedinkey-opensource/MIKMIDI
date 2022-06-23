//
//  MIKMIDISequence+MIKMIDIPrivate.h
//  MIKMIDI
//
//  Created by Chris Flesner on 6/30/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDISequence.h>
#import <MIKMIDI/MIKMIDICompilerCompatibility.h>

@class MIKMIDISequencer;

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDISequence ()

@property (nonatomic, weak, readwrite, nullable) MIKMIDISequencer *sequencer;

@end

NS_ASSUME_NONNULL_END
