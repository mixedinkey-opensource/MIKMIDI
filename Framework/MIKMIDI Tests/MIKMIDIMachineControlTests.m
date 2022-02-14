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
    NSArray *bytes = @[@(0xf0), @(0x7f), @(0x7f), @(0x06), @(0x01)];
    MIDIPacket packet = MIKMIDIPacketCreate(0, bytes.count, bytes);

    MIKMIDICommand *command = [MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertTrue([command isMemberOfClass:[MIKMIDIMachineControlCommand class]]);
}

- (void)testMMCLocateTargetCommand
{
    NSArray *bytes = @[@(0xf0), @(0x7f), @(0x7f), @(0x06), @(0x44), @(0x06), @(0x01), @(0x21), @(0x00), @(0x00), @(0x00), @(0x00), @(0xf7)];
    MIDIPacket packet = MIKMIDIPacketCreate(0, bytes.count, bytes);

    MIKMIDICommand *command = [MIKMIDICommand commandWithMIDIPacket:&packet];
    XCTAssertTrue([command isMemberOfClass:[MIKMIDIMachineControlLocateTargetCommand class]]);

    bytes = @[@(0xf0), @(0x7f), @(0x7f), @(0x06), @(0x45), @(0x06), @(0x01), @(0x21), @(0x00), @(0x00), @(0x00), @(0x00), @(0xf7)];
    packet = MIKMIDIPacketCreate(0, bytes.count, bytes);
    command = [MIKMIDICommand commandWithMIDIPacket:&packet]; // Should not be a locate command because message type byte is 0x45, not 0x44
    XCTAssertFalse([command isMemberOfClass:[MIKMIDIMachineControlLocateTargetCommand class]]);
    XCTAssertTrue([command isMemberOfClass:[MIKMIDIMachineControlCommand class]]);
}
@end
