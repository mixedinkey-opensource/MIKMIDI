//
//  MIKMIDIChannelEventTests.m
//  MIKMIDI Tests
//
//  Created by Andrew R Madsen on 4/8/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIChannelEventTests : XCTestCase

@end

@implementation MIKMIDIChannelEventTests

- (void)testConvertingPolyphonicKeyPressureEventToCommand
{
    MIKMutableMIDIPolyphonicKeyPressureEvent *event = [[MIKMutableMIDIPolyphonicKeyPressureEvent alloc] init];
    event.channel = 3;
    event.pressure = 42;

    XCTAssertEqual(event.channel, 3);
    XCTAssertEqual(event.pressure, 42);
    
    MIKMIDIClock *clock = [MIKMIDIClock clock];
    
    MIKMIDIPolyphonicKeyPressureCommand *command = nil;
    XCTAssertNoThrow(command = (id)[MIKMIDICommand commandFromChannelEvent:event clock:clock]);
    XCTAssertTrue([command isKindOfClass:[MIKMIDIPolyphonicKeyPressureCommand class]]);
    XCTAssertNotNil(command);
    XCTAssertEqual(command.channel, event.channel);
    XCTAssertEqual(command.pressure, event.pressure);
}

- (void)testConvertingChannelPressureEventToCommand
{
    MIKMutableMIDIChannelPressureEvent *event = [[MIKMutableMIDIChannelPressureEvent alloc] init];
    event.channel = 2;
    event.pressure = 27;
    XCTAssertEqual(event.channel, 2);
    XCTAssertEqual(event.pressure, 27);
    
    MIKMIDIClock *clock = [MIKMIDIClock clock];
    
    MIKMIDIChannelPressureCommand *command = nil;
    XCTAssertNoThrow(command = (id)[MIKMIDICommand commandFromChannelEvent:event clock:clock]);
    XCTAssertTrue([command isKindOfClass:[MIKMIDIChannelPressureCommand class]]);
    XCTAssertNotNil(command);
    XCTAssertEqual(command.channel, event.channel);
    XCTAssertEqual(command.pressure, event.pressure);
}

@end
