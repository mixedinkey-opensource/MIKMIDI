//
//  MIKMIDIProgramChangeCommand.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 1/14/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelVoiceCommand.h"

/**
 *  A MIDI program change message.
 */
@interface MIKMIDIProgramChangeCommand : MIKMIDIChannelVoiceCommand

@property (nonatomic, readonly) NSUInteger programNumber;

@end

/**
 *  The mutable counterpart of MIKMIDIProgramChangeCommand
 */
@interface MIKMutableMIDIProgramChangeCommand : MIKMIDIProgramChangeCommand

@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) NSUInteger value;

@property (nonatomic, readwrite) NSUInteger programNumber;

@end