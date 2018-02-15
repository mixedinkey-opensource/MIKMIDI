//
//  MIKMIDISystemExclusiveCommandTests.m
//  MIKMIDI Tests
//
//  Created by Andrew Madsen on 2/15/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDISystemExclusiveCommandTests : XCTestCase

@end

@implementation MIKMIDISystemExclusiveCommandTests

- (void)testSystemExclusiveCommand
{
	Class immutableClass = [MIKMIDISystemExclusiveCommand class];
	Class mutableClass = [MIKMutableMIDISystemExclusiveCommand class];
	
	MIKMIDISystemExclusiveCommand *command = [[immutableClass alloc] init];
	XCTAssert([command isMemberOfClass:[immutableClass class]], @"[[MIKMIDISystemExclusiveCommand alloc] init] did not return an MIKMIDISystemExclusiveCommand instance.");
	XCTAssert([[MIKMIDICommand commandForCommandType:MIKMIDICommandTypeSystemExclusive] isMemberOfClass:[immutableClass class]], @"[MIKMIDICommand commandForCommandType:MIKMIDICommandTypeSystemExclusive] did not return an MIKMIDISystemExclusiveCommand instance.");
	XCTAssert([[command copy] isMemberOfClass:[immutableClass class]], @"[MIKMIDISystemExclusiveCommand copy] did not return an MIKMIDISystemExclusiveCommand instance.");
	XCTAssertEqual(command.commandType, MIKMIDICommandTypeSystemExclusive, @"[[MIKMIDISystemExclusiveCommand alloc] init] produced a command instance with the wrong command type.");
	XCTAssertEqual(command.data.length, 4, "MIKMIDISystemExclusiveCommand had an incorrect data length %@ (should be 4)", @(command.data.length));
	
	MIKMutableMIDISystemExclusiveCommand *mutableCommand = [command mutableCopy];
	XCTAssert([mutableCommand isMemberOfClass:[mutableClass class]], @"-[MIKMIDISystemExclusiveCommand mutableCopy] did not return an mutableClass instance.");
	XCTAssert([[mutableCommand copy] isMemberOfClass:[immutableClass class]], @"-[mutableClass mutableCopy] did not return an MIKMIDISystemExclusiveCommand instance.");
	
	XCTAssertThrows([(MIKMutableMIDISystemExclusiveCommand *)command setSysexData:[NSData data]], @"-[MIKMIDISystemExclusiveCommand setSysexData:] was allowed on immutable instance.");
	XCTAssertThrows([(MIKMutableMIDISystemExclusiveCommand *)command setSysexChannel:10], @"-[MIKMIDISystemExclusiveCommand setSysexChannel:] was allowed on immutable instance.");
	
	XCTAssertNoThrow([mutableCommand setSysexData:[NSData data]], @"-[MIKMIDISystemExclusiveCommand setSysexData:] was not allowed on mutable instance.");
	XCTAssertNoThrow([mutableCommand setSysexChannel:10], @"-[MIKMIDISystemExclusiveCommand setSysexChannel:] was not allowed on mutable instance.");
	
	mutableCommand.sysexChannel = 27;
	XCTAssertEqual(mutableCommand.sysexChannel, 27, @"Setting the sysexChannel on a MIKMutableMIDISystemExclusiveCommand instance failed.");
}

- (void)testSettingSysexData
{
	MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
	NSData *sysexData = [NSData dataWithBytes:(UInt8[]){0x06, 0x44, 0x06, 0x01, 0x21, 0x02, 0x3A, 0x00, 0x00} length:9];
	command.sysexData = sysexData;
	command.manufacturerID = kMIKMIDISysexRealtimeManufacturerID;
	command.sysexChannel = kMIKMIDISysexChannelDisregard;
	XCTAssertEqualObjects(command.sysexData, sysexData);
	XCTAssertEqual(command.data.length, command.sysexData.length+4);
}

- (void)testCreatingSysexFromMIDIPacket
{
	MIKMutableMIDISystemExclusiveCommand *sysex = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
	sysex.manufacturerID = kMIKMIDISysexNonRealtimeManufacturerID;
	sysex.sysexChannel = kMIKMIDISysexChannelDisregard;
	sysex.sysexData = [NSData dataWithBytes:(UInt8[]){0x41, 0x42, 0x43, 0x44, 0x45} length:5];
	MIDIPacket *packet = MIKMIDIPacketCreateFromCommands(0, @[sysex]);
	
	NSArray *commands = [MIKMIDICommand commandsWithMIDIPacket:packet];
	XCTAssertEqual(commands.count, 1);
	MIKMIDISystemExclusiveCommand *command = commands[0];
	XCTAssertTrue([command isKindOfClass:[MIKMIDISystemExclusiveCommand class]]);
}

- (void)testManufacturerSpecificSystemExclusiveCommand
{
	MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
	command.manufacturerID = 0x41; // Roland
	XCTAssertEqual(command.manufacturerID, 0x41, @"Setting the manufacturerID on a MIKMutableMIDISystemExclusiveCommand instance failed.");
	
	XCTAssertEqual(command.sysexChannel, 0, @"Sysex channel for a manufacturer specific sysex command should be 0");
	
	command.manufacturerID = 0x002076;
	XCTAssertEqual(command.manufacturerID, 0x002076, @"Setting a 3-byte manufacturerID on a MIKMutableMIDISystemExclusiveCommand instance failed.");
}

@end
