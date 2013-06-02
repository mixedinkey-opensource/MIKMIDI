//
//  MIKMIDICommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

typedef NS_ENUM(NSUInteger, MIKMIDICommandType) {
	MIKMIDICommandTypeControlChange = 0x0b,
};

@interface MIKMIDICommand : NSObject <NSCopying>

+ (instancetype)commandWithMIDIPacket:(MIDIPacket *)packet;

@property (nonatomic, strong, readonly) NSDate *timestamp;
@property (nonatomic, readonly) UInt8 commandType;
@property (nonatomic, readonly) UInt8 channel;
@property (nonatomic, readonly) UInt8 dataByte1;
@property (nonatomic, readonly) UInt8 dataByte2;

@property (nonatomic, readonly) MIDITimeStamp midiTimestamp;
@property (nonatomic, strong, readonly) NSData *data;

@end

@interface MIKMutableMIDICommand : MIKMIDICommand

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) UInt8 commandType;
@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, strong, readwrite) NSData *data;

@end

@interface MIKMIDIControlChangeCommand : MIKMIDICommand

@property (nonatomic, readonly) NSUInteger controllerNumber;
@property (nonatomic, readonly) NSUInteger controllerValue;

@end

@interface MIKMutableMIDIControlChangeCommand : MIKMutableMIDICommand

@property (nonatomic, readwrite) NSUInteger controllerNumber;
@property (nonatomic, readwrite) NSUInteger controllerValue;

@end

// Pass 0 for listSize to use standard MIDIPacketList size (i.e. sizeof(MIDIPacketList) )
BOOL MIKMIDIPacketListFromCommands(MIDIPacketList *inOutPacketList, ByteCount listSize, NSArray *commands);