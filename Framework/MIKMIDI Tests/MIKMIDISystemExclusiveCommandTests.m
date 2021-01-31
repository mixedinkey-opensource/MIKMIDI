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

- (void)testInitializingSystemExclusiveCommand
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

- (void)testSysexCommandConvenienceMethod
{
    Class immutableClass = [MIKMIDISystemExclusiveCommand class];
    Class mutableClass = [MIKMutableMIDISystemExclusiveCommand class];

    NSDate *timestamp = [NSDate date];
    NSData *sysexData = [NSData dataWithBytes:(UInt8[]){0xde, 0xad, 0xbe, 0xef} length:4];
    MIKMIDISystemExclusiveCommand *command =
    [MIKMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID:0x41
                                                                    sysexChannel:1
                                                                       sysexData:sysexData
                                                                       timestamp:timestamp];
    XCTAssert([command isMemberOfClass:[immutableClass class]], @"[MIKMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID:...] did not return an MIKMIDISystemExclusiveCommand instance.");
    XCTAssertEqual(command.commandType, MIKMIDICommandTypeSystemExclusive, @"[MIKMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID] produced a command instance with the wrong command type.");
    XCTAssertEqual(command.data.length, 7, "MIKMIDISystemExclusiveCommand had an incorrect data length %@ (should be 4)", @(command.data.length));
    XCTAssertEqual(command.manufacturerID, 0x41, @"The manufacturerID on a MIKMIDISystemExclusiveCommand instance was incorrect.");
    XCTAssertEqual(command.sysexChannel, 0, @"The sysexChannel on a MIKMIDISystemExclusiveCommand instance was incorrect.");
    XCTAssertEqualObjects(command.sysexData, sysexData, @"The sysexData on a MIKMIDISystemExclusiveCommand instance was incorrect.");

    MIKMutableMIDISystemExclusiveCommand *mutableCommand =
    [MIKMutableMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID:0x41
                                                                    sysexChannel:1
                                                                       sysexData:sysexData
                                                                       timestamp:timestamp];
    XCTAssert([mutableCommand isMemberOfClass:[mutableClass class]], @"[MIKMutableMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID:...] did not return an MIKMIDISystemExclusiveCommand instance.");
    XCTAssertEqual(mutableCommand.commandType, MIKMIDICommandTypeSystemExclusive, @"[MIKMutableMIDISystemExclusiveCommand systemExclusiveCommandWithManufacturerID] produced a command instance with the wrong command type.");
    XCTAssertEqual(mutableCommand.data.length, 7, "MIKMutableMIDISystemExclusiveCommand had an incorrect data length %@ (should be 4)", @(command.data.length));
    XCTAssertEqual(mutableCommand.manufacturerID, 0x41, @"The manufacturerID on a MIKMutableMIDISystemExclusiveCommand instance was incorrect.");
    XCTAssertEqual(mutableCommand.sysexChannel, 0, @"The sysexChannel on a MIKMutableMIDISystemExclusiveCommand instance was incorrect.");
    XCTAssertEqualObjects(mutableCommand.sysexData, sysexData, @"The sysexData on a MIKMutableMIDISystemExclusiveCommand instance was incorrect.");

    XCTAssertNoThrow([mutableCommand setSysexData:[NSData data]], @"-[MIKMIDISystemExclusiveCommand setSysexData:] was not allowed on mutable instance.");
    XCTAssertNoThrow([mutableCommand setSysexChannel:10], @"-[MIKMIDISystemExclusiveCommand setSysexChannel:] was not allowed on mutable instance.");

    mutableCommand.manufacturerID = 0x42;
    XCTAssertEqual(mutableCommand.manufacturerID, 0x42, @"Setting the manufacturerID on a MIKMutableMIDISystemExclusiveCommand instance failed.");
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

- (void)testChangingManufacturerIDLength
{
    MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
    command.manufacturerID = 0x41; // Roland
    XCTAssertFalse(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.data.length, 4); // Status, 1-byte manufacturer, (zero) channel, end delimiter byte

    command.manufacturerID = 0x414243;
    XCTAssertTrue(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.manufacturerID, 0x414243, @"Changing the manufacturerID length on a MIKMutableMIDISystemExclusiveCommand instance failed.");
    XCTAssertEqual(command.data.length, 6); // Status, 3-byte manufacturer, (zero) channel, end delimiter byte

    command.manufacturerID = 0x41;
    XCTAssertFalse(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.manufacturerID, 0x41, @"Changing the manufacturerID length on a MIKMutableMIDISystemExclusiveCommand instance failed.");
    XCTAssertEqual(command.data.length, 4); // Status, 1-byte manufacturer, (zero) channel, end delimiter byte
}

- (void)testForcedThreeByteManufacturerIDLength
{
    MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
    command.manufacturerID = 0x41; // Roland
    XCTAssertFalse(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.data.length, 4); // Status, 1-byte manufacturer, (zero) channel, end delimiter byte

    command.includesThreeByteManufacturerID = YES;
    XCTAssertEqual(command.manufacturerID, 0x41, @"manufacturerID is wrong after includesThreeByteManufacturerID change");
    XCTAssertTrue(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.data.length, 6); // Status, 3-byte manufacturer, (zero) channel, end delimiter byte

    command.includesThreeByteManufacturerID = NO;
    XCTAssertEqual(command.manufacturerID, 0x41, @"manufacturerID is wrong after includesThreeByteManufacturerID change");
    XCTAssertFalse(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.data.length, 4); // Status, 1-byte manufacturer, (zero) channel, end delimiter byte
}

- (void)testForcedThreeByteManufacturerIDLengthWithSysexData
{
    MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
    command.includesThreeByteManufacturerID = YES;
    command.manufacturerID = 0x41; // Roland
    XCTAssertEqual(command.manufacturerID, 0x41, @"manufacturerID is wrong after includesThreeByteManufacturerID change");
    XCTAssertEqual(command.data.length, 6); // Status, 3-byte manufacturer, (zero) channel, end delimiter byte
    XCTAssertTrue(command.includesThreeByteManufacturerID);

    command.sysexData = [NSData dataWithBytes:(UInt8[]){0xde, 0xad, 0xbe, 0xef} length:4];
    XCTAssertEqual(command.manufacturerID, 0x41, @"manufacturerID is wrong after setting sysexData change");
    XCTAssertEqual(command.data.length, 9); // Status, 3-byte manufacturer, 4-byte sysex data, end delimiter byte
}

- (void)testSettingIncludesThreeByteManufacturerIDWithThreeByteManufacturerID
{
    MIKMutableMIDISystemExclusiveCommand *command = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
    command.manufacturerID = 0x414243;
    XCTAssertTrue(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.manufacturerID, 0x414243, @"Changing the manufacturerID length on a MIKMutableMIDISystemExclusiveCommand instance failed.");
    XCTAssertEqual(command.data.length, 6); // Status, 3-byte manufacturer, (zero) channel, end delimiter byte

    command.includesThreeByteManufacturerID = NO;
    XCTAssertTrue(command.includesThreeByteManufacturerID);
    XCTAssertEqual(command.manufacturerID, 0x414243, @"manufacturerID is wrong after includesThreeByteManufacturerID change");
    XCTAssertEqual(command.data.length, 6); // Status, 3-byte manufacturer, (zero) channel, end delimiter byte
}

- (void)testParsingManufacturerID
{
    // 0xf0 00 00 41 00 f7
    MIDIPacket packet = MIKMIDIPacketCreate(0, 6, @[@0xf0, @0, @0, @0x41, @0, @0xf7]);
    MIKMIDISystemExclusiveCommand *command = (MIKMIDISystemExclusiveCommand *)[MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertNotNil(command);
    XCTAssertTrue([command isKindOfClass:[MIKMIDISystemExclusiveCommand class]]);
    XCTAssertEqual(command.manufacturerID, 0x41);
    XCTAssertTrue(command.includesThreeByteManufacturerID);

    // 0xf0 41 00 f7
    packet = MIKMIDIPacketCreate(0, 4, @[@0xf0, @0x41, @0, @0xf7]);
    command = (MIKMIDISystemExclusiveCommand *)[MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertNotNil(command);
    XCTAssertTrue([command isKindOfClass:[MIKMIDISystemExclusiveCommand class]]);
    XCTAssertEqual(command.manufacturerID, 0x41);
    XCTAssertFalse(command.includesThreeByteManufacturerID);

    // 0xf0 00 42 43 00 f7
    packet = MIKMIDIPacketCreate(0, 6, @[@0xf0, @0, @0x42, @0x43, @0, @0xf7]);
    command = (MIKMIDISystemExclusiveCommand *)[MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertNotNil(command);
    XCTAssertTrue([command isKindOfClass:[MIKMIDISystemExclusiveCommand class]]);
    XCTAssertEqual(command.manufacturerID, 0x4243);
    XCTAssertTrue(command.includesThreeByteManufacturerID);
}

@end
