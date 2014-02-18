//
//  MIKMIDICommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

/**
 *  Types of MIDI messages. These values correspond directly to the MIDI command type values
 *  found in MIDI message data.
 *
 *  @note Not all of these MIDI message types are currently explicitly supported by MIKMIDI.
 */
typedef NS_ENUM(NSUInteger, MIKMIDICommandType) {
	MIKMIDICommandTypeNoteOff = 0x8f,
	MIKMIDICommandTypeNoteOn = 0x9f,
	MIKMIDICommandTypePolyphonicKeyPressure = 0xaf,
	MIKMIDICommandTypeControlChange = 0xbf,
	MIKMIDICommandTypeProgramChange = 0xcf,
	MIKMIDICommandTypeChannelPressure = 0xdf,
	MIKMIDICommandTypePitchWheelChange = 0xef,
	MIKMIDICommandTypeSystemMessage = 0xff,
	MIKMIDICommandTypeSystemExclusive = 0xf0,
	MIKMIDICommandTypeSystemTimecodeQuarterFrame = 0xf1,
	MIKMIDICommandTypeSystemSongPositionPointer = 0xf2,
	MIKMIDICommandTypeSystemSongSelect = 0xf3,
	MIKMIDICommandTypeSystemTuneRequest = 0xf6,
	MIKMIDICommandTypeSystemTimingClock = 0xf8,
	MIKMIDICommandTypeSystemStartSequence = 0xfa,
	MIKMIDICommandTypeSystemContinueSequence = 0xfb,
	MIKMIDICommandTypeSystemStopSequence = 0xfc,
	MIKMIDICommandTypeSystemKeepAlive = 0xfe,
};

@class MIKMIDIMappingItem;

/**
 *  In MIKMIDI, MIDI messages are objects. Specifically, they are instances of MIKMIDICommand or one of its
 *  subclasses. MIKMIDICommand's subclasses each represent a specific type of MIDI message, for example,
 *  control change command messages will be instances of MIKMIDIControlChangeCommand.
 *  MIKMIDICommand includes properties for getting information and data common to all MIDI messages.
 *  Its subclasses implement additional method and properties specific to messages of their associated type.
 *
 *  MIKMIDICommand is also available in mutable variants, most useful for creating commands to be sent out
 *  by your application.
 *
 *  To create a new command, typically, you should use +commandForCommandType:.
 */
@interface MIKMIDICommand : NSObject <NSCopying>

/**
 *  Convenience method for creating a new MIKMIDICommand instance from a MIDIPacket as received or created
 *  using CoreMIDI functions. For command types for which there is a specific MIKMIDICommand subclass,
 *  an instance of the appropriate subclass will be returned.
 *
 *  @note This method is used by MIKMIDI's internal machinery, and its use by MIKMIDI
 *  clients, while not disallowed, is not typical. Normally, +commandForCommandType: should be used.
 *
 *  @param packet A pointer to an MIDIPacket struct.
 *
 *  @return For supported command types, an initialized MIKMIDICommand subclass. Otherwise, an instance
 *  of MIKMIDICommand itself. nil if there is an error.
 *
 *  @see +commandForCommandType:
 */
+ (instancetype)commandWithMIDIPacket:(MIDIPacket *)packet;

/**
 *  Convenience method for creating a new MIKMIDICommand. For command types for which there is a
 *  specific MIKMIDICommand subclass, an instance of the appropriate subclass will be returned.
 *
 *  @param commandType The type of MIDI command to create. See MIKMIDICommandType for a list
 *  of possible values.
 *
 *  @return For supported command types, an initialized MIKMIDICommand subclass. Otherwise, an instance
 *  of MIKMIDICommand itself. nil if there is an error.
 */
+ (instancetype)commandForCommandType:(MIKMIDICommandType)commandType; // Most useful for mutable commands

/**
 *  The time at which the MIDI message was received. Will be set for commands received from a connected MIDI source. For commands
 *  to be sent (ie. created by the MIKMIDI-using application), this must be set manually.
 */
@property (nonatomic, strong, readonly) NSDate *timestamp;

/**
 *  The receiver's command type. See MIKMIDICommandType for a list of possible values.
 */
@property (nonatomic, readonly) MIKMIDICommandType commandType;

/**
 *  The first byte of the MIDI data (after the command type).
 */
@property (nonatomic, readonly) UInt8 dataByte1;

/**
 *  The second byte of the MIDI data (after the command type).
 */
@property (nonatomic, readonly) UInt8 dataByte2;

/**
 *  The timestamp for the receiver, expressed as a host clock time. This is the timestamp
 *  used by CoreMIDI. Usually the timestamp property, which returns an NSDate, will be more useful.
 *
 *  @see -timestamp
 */
@property (nonatomic, readonly) MIDITimeStamp midiTimestamp;

/**
 *  The raw data that makes up the receiver.
 */
@property (nonatomic, copy, readonly) NSData *data;

/**
 *  Optional mapping item used to route the command. This must be set by client code that handles
 *  receiving MIDI commands. Allows responders to understand how a command was mapped, especially
 *  useful to determine interaction type so that responders can interpret the command correctly.
 */
@property (nonatomic, strong) MIKMIDIMappingItem *mappingItem;

@end

/**
 *  Mutable subclass of MIKMIDICommand. All MIKMIDICommand subclasses have mutable variants.
 */
@interface MIKMutableMIDICommand : MIKMIDICommand

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite) NSData *data;

@end

/**
 *  Returns (by reference) a CoreMIDI MIDIPacketList created from an array of MIKMIDICommand instances.
 *  Used by MIKMIDI when sending commands. Typically, this is not needed by clients of MIKMIDI.
 *
 *  @param inOutPacketList A pointer to a MIDIPacketList structure.
 *  @param listSize        The size in bytes of the MIDIPacketList, or 0 to use sizeof() (ie. only a single command).
 *  @param commands        An array of MIKMIDICommand instances.
 *
 *  @return YES if creating the packet list was successful, NO if an error occurred.
 */
BOOL MIKMIDIPacketListFromCommands(MIDIPacketList *inOutPacketList, ByteCount listSize, NSArray *commands);

