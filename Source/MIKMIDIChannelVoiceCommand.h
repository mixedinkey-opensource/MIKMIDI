//
//  MIKMIDIChannelVoiceCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDICommand.h"

@interface MIKMIDIChannelVoiceCommand : MIKMIDICommand

@property (nonatomic, readonly) UInt8 channel;
@property (nonatomic, readonly) NSUInteger value;

@end

@interface MIKMutableMIDIChannelVoiceCommand : MIKMIDIChannelVoiceCommand

@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) NSUInteger value;

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite) NSData *data;

@end
