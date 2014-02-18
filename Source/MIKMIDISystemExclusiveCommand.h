//
//  MIKMIDISystemExclusiveCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISystemMessageCommand.h"

#define kMIKMIDISysexNonRealtimeManufacturerID 0x7E
#define kMIKMIDISysexRealtimeManufacturerID 0x7F

#define kMIKMIDISysexChannelDisregard 0x7F
#define kMIKMIDISysexEndDelimiter 0xF7

@interface MIKMIDISystemExclusiveCommand : MIKMIDISystemMessageCommand

@property (nonatomic, readonly) UInt32 manufacturerID;
@property (nonatomic, readonly) UInt8 sysexChannel;
@property (nonatomic, strong, readonly) NSData *sysexData;
@property (nonatomic, readonly, getter = isUniversal) BOOL universal;

+ (instancetype)identityRequestCommand;

@end

@interface MIKMutableMIDISystemExclusiveCommand : MIKMIDISystemExclusiveCommand

@property (nonatomic, readwrite) UInt32 manufacturerID;
@property (nonatomic, readwrite) UInt8 sysexChannel;
@property (nonatomic, strong, readwrite) NSData *sysexData;

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite) NSData *data;

@end