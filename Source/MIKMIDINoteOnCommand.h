//
//  MIKMIDINoteOnCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelVoiceCommand.h"

/**
 *  A MIDI note on message.
 */
@interface MIKMIDINoteOnCommand : MIKMIDIChannelVoiceCommand

/**
 *  The note number for the message. In the range 0-127.
 */
@property (nonatomic, readonly) NSUInteger note;

/**
 *  Velocity of the note off message. In the range 0-127.
 */
@property (nonatomic, readonly) NSUInteger velocity;

@end

/**
 *  The mutable counterpart of MIKMIDINoteOnCommand.
 */
@interface MIKMutableMIDINoteOnCommand : MIKMIDINoteOnCommand

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) NSUInteger value;

@property (nonatomic, readwrite) NSUInteger note;
@property (nonatomic, readwrite) NSUInteger velocity;

@end
