//
//  MIKMIDIMetronome.h
//  MIKMIDI
//
//  Created by Chris Flesner on 11/24/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEndpointSynthesizer.h"


@interface MIKMIDIMetronome : MIKMIDIEndpointSynthesizer

@property (nonatomic) MIDINoteMessage tickMessage;
@property (nonatomic) MIDINoteMessage tockMessage;

@end

@interface MIKMIDIMetronome (Private)

/**
 *  This should not be called directly. Consider it private to MIKMIDI.
 */
- (BOOL)setupMetronome;

@end