//
//  MIKMIDIChannelEvent.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/3/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDIEvent.h>

@interface MIKMIDIChannelEvent : MIKMIDIEvent

/**
 *  Convenience method for creating a new MIKMIDIChannelEvent from a CoreMIDI MIDIChannelMessage struct.
 *
 *  @param timeStamp A MusicTimeStamp value indicating the timestamp for the event.
 *  @param message A MIDIChannelMessage struct containing properties for the event.
 *
 *  @return A new instance of a subclass of MIKMIDIChannelEvent, or nil if there is an error.
 */
+ (instancetype)channelEventWithTimeStamp:(MusicTimeStamp)timeStamp message:(MIDIChannelMessage)message;

// Properties

/**
 *  The channel for the MIDI event.
 */
@property (nonatomic, readonly) UInt8 channel;

/**
 *  The first byte of data for the event.
 */
@property (nonatomic, readonly) UInt8 dataByte1;

/**
 *  The second byte of data for the event.
 */
@property (nonatomic, readonly) UInt8 dataByte2;

@end

/**
 *  The mutable counterpart of MIKMIDIChannelEvent.
 */
@interface MIKMutableMIDIChannelEvent : MIKMIDIChannelEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, strong, readwrite) NSMutableData *data;
@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@end

#pragma mark -

#import <MIKMIDI/MIKMIDICommand.h>

@class MIKMIDIClock;

@interface MIKMIDICommand (MIKMIDIChannelEventToCommands)

+ (instancetype)commandFromChannelEvent:(MIKMIDIChannelEvent *)event clock:(MIKMIDIClock *)clock;

@end