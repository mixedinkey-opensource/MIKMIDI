//
//  MIKMIDINoteCommandTests.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 9/18/17.
//  Copyright © 2017 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDINoteCommandTests : XCTestCase

@end

@implementation MIKMIDINoteCommandTests

- (void)testCreatingGenericNoteCommands
{
	MIKMIDINoteCommand *noteOn = [MIKMIDINoteCommand noteCommandWithNote:60 velocity:64 channel:1 isNoteOn:YES midiTimeStamp:0];
	XCTAssertTrue([noteOn isKindOfClass:[MIKMIDINoteOnCommand class]]);
	XCTAssertEqual(noteOn.note, 60);
	XCTAssertEqual(noteOn.velocity, 64);
	XCTAssertEqual(noteOn.channel, 1);
	XCTAssertThrows([(MIKMutableMIDINoteOnCommand *)noteOn setNote:0]);
	
	MIKMIDINoteCommand *noteOff = [MIKMIDINoteCommand noteCommandWithNote:60 velocity:64 channel:1 isNoteOn:NO midiTimeStamp:0];
	XCTAssertTrue([noteOff isKindOfClass:[MIKMIDINoteOffCommand class]]);
	XCTAssertEqual(noteOff.note, 60);
	XCTAssertEqual(noteOff.velocity, 64);
	XCTAssertEqual(noteOff.channel, 1);
	XCTAssertThrows([(MIKMutableMIDINoteOffCommand *)noteOn setNote:0]);
	
	XCTAssertThrows([[MIKMIDINoteCommand alloc] init]);
	XCTAssertNoThrow(noteOn = [[MIKMIDINoteOnCommand alloc] init]);
	XCTAssertNoThrow(noteOff = [[MIKMIDINoteOffCommand alloc] init]);
	XCTAssertTrue([noteOn isKindOfClass:[MIKMIDINoteOnCommand class]]);
	XCTAssertTrue([noteOff isKindOfClass:[MIKMIDINoteOffCommand class]]);
}

- (void)testCreatingNoteCommandsWithMIDIPacket
{
	MIDIPacket *packet = MIKMIDIPacketCreateFromCommands(0, @[[MIKMIDINoteOnCommand noteOnCommandWithNote:60 velocity:64 channel:1 midiTimeStamp:0]]);
	MIKMIDINoteOnCommand *noteOn = (MIKMIDINoteOnCommand *)[MIKMIDICommand commandWithMIDIPacket:packet];
	XCTAssertTrue([noteOn isKindOfClass:[MIKMIDINoteOnCommand class]]);
	XCTAssertEqual(noteOn.note, 60);
	XCTAssertEqual(noteOn.velocity, 64);
	XCTAssertEqual(noteOn.channel, 1);
	MIKMIDIPacketFree(packet);
	
	packet = MIKMIDIPacketCreateFromCommands(0, @[[MIKMIDINoteOffCommand noteOffCommandWithNote:60 velocity:64 channel:1 midiTimeStamp:0]]);
	MIKMIDINoteOffCommand *noteOff = (MIKMIDINoteOffCommand *)[MIKMIDICommand commandWithMIDIPacket:packet];
	XCTAssertTrue([noteOff isKindOfClass:[MIKMIDINoteOffCommand class]]);
	XCTAssertEqual(noteOff.note, 60);
	XCTAssertEqual(noteOff.velocity, 64);
	XCTAssertEqual(noteOff.channel, 1);
	MIKMIDIPacketFree(packet);
}

- (void)testCreatingMutableNoteCommands
{
	MIKMutableMIDINoteCommand *mutableNote = nil;
	XCTAssertThrows(mutableNote = [[MIKMutableMIDINoteCommand alloc] init]);
	
	MIKMutableMIDINoteOnCommand *noteOn = nil;
	XCTAssertNoThrow(noteOn = [[MIKMutableMIDINoteOnCommand alloc] init]);
	XCTAssertTrue([noteOn isKindOfClass:[MIKMutableMIDINoteOnCommand class]]);
	XCTAssertNoThrow([noteOn setNote:60]);
	XCTAssertThrowsSpecificNamed([(id)noteOn setNoteOn:NO], NSException, NSInvalidArgumentException);
	XCTAssertNoThrow([(id)noteOn setNoteOn:YES]);
	
	MIKMutableMIDINoteOffCommand *noteOff = nil;
	XCTAssertNoThrow(noteOff = [[MIKMutableMIDINoteOffCommand alloc] init]);
	XCTAssertTrue([noteOff isKindOfClass:[MIKMutableMIDINoteOffCommand class]]);
	XCTAssertNoThrow([noteOff setNote:60]);
	XCTAssertThrowsSpecificNamed([(id)noteOff setNoteOn:YES], NSException, NSInvalidArgumentException);
	XCTAssertNoThrow([(id)noteOff setNoteOn:NO]);
}

- (void)testConvertingToNoteOff
{
	MIKMIDINoteOnCommand *zeroVelocityNoteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:60 velocity:0 channel:0 timestamp:nil];
	
	MIKMIDINoteOffCommand *noteOff = [MIKMIDINoteOffCommand noteOffCommandWithNoteCommand:zeroVelocityNoteOn];
	XCTAssertNotNil(noteOff);
	XCTAssertEqual(noteOff.note, 60);
	XCTAssertEqual(noteOff.velocity, 0);
	XCTAssertEqual(noteOff.channel, 0);
	XCTAssertEqualWithAccuracy(noteOff.timestamp.timeIntervalSinceReferenceDate, zeroVelocityNoteOn.timestamp.timeIntervalSinceReferenceDate, 1e-3);
	
	MIKMIDINoteOnCommand *nonzeroVelocityNoteOn = [MIKMIDINoteOnCommand noteOnCommandWithNote:60 velocity:127 channel:0 timestamp:nil];
	XCTAssertNil([MIKMIDINoteOffCommand noteOffCommandWithNoteCommand:nonzeroVelocityNoteOn]);
	
	MIKMIDINoteOffCommand *newNoteOff = [MIKMIDINoteOffCommand noteOffCommandWithNoteCommand:noteOff];
	XCTAssertNotNil(newNoteOff);
	XCTAssertEqual(newNoteOff.note, 60);
	XCTAssertEqual(newNoteOff.velocity, 0);
	XCTAssertEqual(newNoteOff.channel, 0);
	XCTAssertEqualWithAccuracy(newNoteOff.timestamp.timeIntervalSinceReferenceDate, noteOff.timestamp.timeIntervalSinceReferenceDate, 1e-3);
}

@end
