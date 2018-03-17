//
//  MIKMIDIFourteenBitCCCommandTests.m
//  MIKMIDI Tests
//
//  Created by Andrew Madsen on 2/7/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIFourteenBitCCCommandTests : XCTestCase

@end

@implementation MIKMIDIFourteenBitCCCommandTests

- (void)testValidFourteenBitCoalescing
{
	MIKMIDIControlChangeCommand *msbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:10 value:33];
	MIKMIDIControlChangeCommand *lsbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:42 value:3];
	MIKMIDIControlChangeCommand *coalescedCommand = [MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:msbCommand andLSBCommand:lsbCommand];
	XCTAssertNotNil(coalescedCommand);
	XCTAssertEqual(coalescedCommand.controllerNumber, msbCommand.controllerNumber);
	XCTAssertEqual(coalescedCommand.controllerValue, 33);
	XCTAssertEqual(coalescedCommand.value, 33);
	XCTAssertEqual(coalescedCommand.fourteenBitValue, 4227);
}

- (void)testInvalidFourteenBitCoalescing
{
	MIKMIDIControlChangeCommand *msbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:42 value:33];
	MIKMIDIControlChangeCommand *lsbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:42 value:3];
	MIKMIDIControlChangeCommand *coalescedCommand = [MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:msbCommand andLSBCommand:lsbCommand];
	XCTAssertNil(coalescedCommand);
	
	msbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:10 value:33];
	lsbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:27 value:3];
	coalescedCommand = [MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:msbCommand andLSBCommand:lsbCommand];
	XCTAssertNil(coalescedCommand);
	
	msbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:10 value:33];
	lsbCommand = [MIKMIDIControlChangeCommand controlChangeCommandWithControllerNumber:35 value:3];
	coalescedCommand = [MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:msbCommand andLSBCommand:lsbCommand];
	XCTAssertNil(coalescedCommand);
}

- (void)testDirectlyCreatingFourteenBitCommand
{
	MIKMIDIControlChangeCommand *fourteenBitCommand = [MIKMIDIControlChangeCommand fourteenBitControlChangeCommandWithControllerNumber:27 value:4227];
	XCTAssertNotNil(fourteenBitCommand);
	XCTAssertEqual(fourteenBitCommand.controllerNumber, 27);
	XCTAssertEqual(fourteenBitCommand.fourteenBitValue, 4227);
	XCTAssertEqual(fourteenBitCommand.controllerValue, 33);
}

- (void)testSplittingFourteenBitCommand
{
	MIKMutableMIDIControlChangeCommand *fourteenBitCommand = [MIKMutableMIDIControlChangeCommand fourteenBitControlChangeCommandWithControllerNumber:27 value:4227];
	fourteenBitCommand.channel = 7;
	
	MIKMIDIControlChangeCommand *msbCommand = [fourteenBitCommand commandForMostSignificantBits];
	XCTAssertNotNil(msbCommand);
	XCTAssertEqual(msbCommand.controllerValue, 33);
	XCTAssertEqual(msbCommand.channel, fourteenBitCommand.channel);
	XCTAssertFalse(msbCommand.isFourteenBitCommand);
	
	MIKMIDIControlChangeCommand *lsbCommand = [fourteenBitCommand commandForLeastSignificantBits];
	XCTAssertNotNil(lsbCommand);
	XCTAssertEqual(lsbCommand.controllerValue, 3);
	XCTAssertEqual(lsbCommand.channel, fourteenBitCommand.channel);
	XCTAssertFalse(lsbCommand.isFourteenBitCommand);
	
	MIKMIDIControlChangeCommand *coalescedCommand = [MIKMIDIControlChangeCommand commandByCoalescingMSBCommand:msbCommand andLSBCommand:lsbCommand];
	XCTAssertNotNil(coalescedCommand);
	XCTAssertEqualObjects(fourteenBitCommand, coalescedCommand);
}

@end
