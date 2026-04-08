//
//  MIKMIDIMachineControlTests.m
//  MIKMIDI Tests
//
//  Created by Andrew R Madsen on 2/13/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIMachineControlTests : XCTestCase

@end

@implementation MIKMIDIMachineControlTests

- (void)testGenericMIDIMachineControlCommand
{
    Class immutableClass = [MIKMIDIMachineControlCommand class];
    Class mutableClass = [MIKMutableMIDIMachineControlCommand class];

    NSArray *bytes = @[@(0xf0), @(0x7f), @(0xab), @(0x07), @(0x01)];
    MIDIPacket packet = MIKMIDIPacketCreate(0, bytes.count, bytes);

    MIKMIDIMachineControlCommand *command = [MIKMIDIMachineControlCommand commandWithMIDIPacket:&packet];
    XCTAssertTrue([command isMemberOfClass:[MIKMIDIMachineControlCommand class]]);
    XCTAssertEqual(command.deviceAddress, 0xab);
    XCTAssertEqual(command.direction, MIKMIDIMachineControlDirectionResponse);
    XCTAssertEqual(command.MMCCommandType, MIKMIDIMachineControlCommandTypeStop);
    XCTAssertEqual(command.commandType, MIKMIDICommandTypeSystemExclusive, @"[[MIKMIDIMachineControlCommand alloc] init] produced a command instance with the wrong command type.");
    XCTAssert([[command copy] isMemberOfClass:immutableClass], @"[MIKMIDIMachineControlCommand copy] did not return an MIKMIDIMachineControlCommand instance.");
    XCTAssert([[command mutableCopy] isMemberOfClass:mutableClass], @"-[MIKMIDIMachineControlCommand mutableCopy] did not return a mutableClass instance.");


    MIKMutableMIDIMachineControlCommand *mutableCommand = [[MIKMutableMIDIMachineControlCommand alloc] init];
    XCTAssert([mutableCommand isMemberOfClass:mutableClass], @"-[MIKMIDIMachineControlCommand mutableCopy] did not return a mutableClass instance.");
    XCTAssert([[mutableCommand copy] isMemberOfClass:immutableClass], @"[MIKMutableMIDIMachineControlCommand copy] did not return an MIKMIDIMachineControlCommand instance.");
    XCTAssertEqual(mutableCommand.commandType, MIKMIDICommandTypeSystemExclusive, @"[[MIKMIDIMachineControlCommand alloc] init] produced a command instance with the wrong command type.");

    XCTAssertEqual(mutableCommand.deviceAddress, 0x7f);
    XCTAssertEqual(mutableCommand.direction, MIKMIDIMachineControlDirectionCommand);
    XCTAssertEqual(mutableCommand.MMCCommandType, MIKMIDIMachineControlCommandTypeUnknown);

    XCTAssertThrows([(MIKMutableMIDIMachineControlCommand *)command setDirection:MIKMIDIMachineControlDirectionResponse]);
    XCTAssertThrows([(MIKMutableMIDIMachineControlCommand *)command setMMCCommandType:MIKMIDIMachineControlCommandTypePlay]);

    XCTAssertNoThrow([mutableCommand setDirection:MIKMIDIMachineControlDirectionResponse]);
    XCTAssertNoThrow([mutableCommand setMMCCommandType:MIKMIDIMachineControlCommandTypePlay]);

    mutableCommand.deviceAddress = 0x9f;
    mutableCommand.direction = MIKMIDIMachineControlDirectionResponse;
    mutableCommand.MMCCommandType = MIKMIDIMachineControlCommandTypeRecordExit;
    XCTAssertEqual(mutableCommand.deviceAddress, 0x9f);
    XCTAssertEqual(mutableCommand.direction, MIKMIDIMachineControlDirectionResponse);
    XCTAssertEqual(mutableCommand.MMCCommandType, MIKMIDIMachineControlCommandTypeRecordExit);

    MIKMIDIMachineControlCommand *createdCommand =
    [MIKMIDIMachineControlCommand machineControlCommandWithDeviceAddress:0xcd
                                                               direction:MIKMIDIMachineControlDirectionResponse
                                                          MMCCommandType:MIKMIDIMachineControlCommandTypePause];
    XCTAssertEqual(createdCommand.deviceAddress, 0xcd);
    XCTAssertEqual(createdCommand.direction, MIKMIDIMachineControlDirectionResponse);
    XCTAssertEqual(createdCommand.MMCCommandType, MIKMIDIMachineControlCommandTypePause);
}

- (void)testMMCLocateTargetCommand
{
    Class immutableClass = [MIKMMCLocateTargetCommand class];
    Class mutableClass = [MIKMutableMMCLocateTargetCommand class];

    NSArray *bytes = @[@(0xf0), @(0x7f), @(0x7f), @(0x06), @(0x44), @(0x06), @(0x01), @(0x21), @(0x07), @(0x13), @(0x15), @(0x00), @(0xf7)];
    MIDIPacket packet = MIKMIDIPacketCreate(0, bytes.count, bytes);

    MIKMMCLocateTargetCommand *command = (MIKMMCLocateTargetCommand *)[MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertTrue([command isMemberOfClass:[MIKMMCLocateTargetCommand class]]);
    XCTAssertEqual(command.timeCodeInSeconds, 4039.84);
    XCTAssertThrows([(MIKMutableMMCLocateTargetCommand *)command setTimeCodeInSeconds:27.0]);

    bytes = @[@(0xf0), @(0x7f), @(0x7f), @(0x06), @(0x45), @(0x06), @(0x01), @(0x21), @(0x00), @(0x00), @(0x00), @(0x00), @(0xf7)];
    packet = MIKMIDIPacketCreate(0, bytes.count, bytes);
    command = (MIKMMCLocateTargetCommand *)[MIKMIDICommand commandWithMIDIPacket:&packet]; // Should not be a locate command because message type byte is 0x45, not 0x44
    XCTAssertFalse([command isMemberOfClass:[MIKMMCLocateTargetCommand class]]);
    XCTAssertTrue([command isMemberOfClass:[MIKMIDIMachineControlCommand class]]);

    MIKMutableMMCLocateTargetCommand *mutableCommand = [[MIKMutableMMCLocateTargetCommand alloc] init];
    XCTAssert([mutableCommand isMemberOfClass:mutableClass], @"-[MIKMMCLocateTargetCommand mutableCopy] did not return a mutableClass instance.");
    XCTAssert([[mutableCommand copy] isMemberOfClass:immutableClass], @"[MIKMutableMMCLocateTargetCommand copy] did not return an MIKMMCLocateTargetCommand instance.");
    XCTAssertEqual(mutableCommand.commandType, MIKMIDICommandTypeSystemExclusive, @"[[MIKMMCLocateTargetCommand alloc] init] produced a command instance with the wrong command type.");

    mutableCommand.timeType = MIKMMCLocateTargetCommandTimeType25FPS;
    mutableCommand.timeCodeInSeconds = 4039.84;
    XCTAssertEqual(mutableCommand.timeType, MIKMMCLocateTargetCommandTimeType25FPS);
    XCTAssertEqual(mutableCommand.timeCodeInSeconds, 4039.84);

    XCTAssertNoThrow([mutableCommand setTimeCodeInSeconds:27.0]);

    MIKMMCLocateTargetCommand *createdCommand = [[MIKMMCLocateTargetCommand alloc] init];
    XCTAssertEqual(createdCommand.MMCCommandType, MIKMIDIMachineControlCommandTypeLocate);
}
@end
