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

@end
