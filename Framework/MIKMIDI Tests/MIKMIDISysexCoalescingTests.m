//
//  MIKMIDISysexCoalescingTests.m
//  MIKMIDI
//
//  Created by Benjamin Jaeger on 15.06.2017.
//  Copyright © 2017 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIDeviceManager ()
@property (nonatomic, strong) MIKMIDIInputPort *inputPort;
@end

@interface MIKMIDIInputPort ()
- (BOOL)coalesceSysexFromMIDIPacket:(const MIDIPacket *)packet toCommandInArray:(NSMutableArray **)commandsArray;
@end

@interface MIKMIDISysexCoalescingTests : XCTestCase
@property (strong) MIKMIDIInputPort *debugInputPort;
@property (strong) NSData *validSysexData;
@end

@implementation MIKMIDISysexCoalescingTests

- (void)setUp
{
	[super setUp];
	_debugInputPort = [MIKMIDIDeviceManager sharedDeviceManager].inputPort;
	_validSysexData = [NSData dataWithBytes:"\xF0\x41\x30\x00\x60\x00\x00\x00\x00\x00\x7f\x00\x00\x00\x00\x7f\x00\x00\x00\x00\x00\x2a\x1d\xF7" length:24];
}

- (void)tearDown
{
	[super tearDown];
	_debugInputPort = nil;
	_validSysexData = nil;
}

- (void)testSinglePacketMessage
{
	NSMutableArray <MIKMIDICommand*> *cmdArray = [NSMutableArray new];
	
	MIDIPacket testPacket = [self packetWithData:_validSysexData];
	
	[_debugInputPort coalesceSysexFromMIDIPacket:&testPacket toCommandInArray:&cmdArray];
	
	XCTAssert([_validSysexData isEqualToData:cmdArray.firstObject.data], @"Single-packet sysex message failed coalescing properly");
}
		
- (void)testMultiplePacketsMessage
{
	NSMutableArray <MIKMIDICommand*> *cmdArray = [NSMutableArray new];
	
	// Split into 6 chunks
	for (NSUInteger i=0; i<6; i++) {
		MIDIPacket chunk = [self packetWithData:[_validSysexData subdataWithRange:NSMakeRange(i*4, 4)]];
		[_debugInputPort coalesceSysexFromMIDIPacket:&chunk toCommandInArray:&cmdArray];
	}
	
	XCTAssert([_validSysexData isEqualToData:cmdArray.firstObject.data], @"Chunked sysex message failed coalescing properly");
}

- (void)testNonTerminatedSysexFollowedByCommand
{
	NSMutableArray <MIKMIDICommand*> *cmdArray = [NSMutableArray new];
	
	// Simulate non terminated sysex packet
	NSRange rangeBeforeEOT = NSMakeRange(0, _validSysexData.length - 1);
	MIDIPacket testPacket = [self packetWithData:[_validSysexData subdataWithRange:rangeBeforeEOT]];
	
	[_debugInputPort coalesceSysexFromMIDIPacket:&testPacket toCommandInArray:&cmdArray];
	
	// Simulate following note-on command
	MIDIPacket noteOnPacket = [self packetWithData:[MIKMIDINoteOnCommand noteOnCommandWithNote:0 velocity:0 channel:0 timestamp:nil].data];
	
	XCTAssert([_debugInputPort coalesceSysexFromMIDIPacket:&noteOnPacket toCommandInArray:&cmdArray] == NO, @"Sysex coalescing should have failed because of an invalid start byte in noteOnPacket");
	XCTAssert([_validSysexData isEqualToData:cmdArray.firstObject.data], @"Sysex coalescing should have ended because of an invalid start byte in noteOnPacket");
}
		
#pragma mark - Helpers

- (MIDIPacket)packetWithData:(NSData *)byteArray
{
	NSParameterAssert(byteArray.length < 256);
	
	MIDIPacket packet = {0};
	packet.timeStamp = mach_absolute_time();
	packet.length = byteArray.length;
	
	Byte *bytes = (Byte *)byteArray.bytes;
	for (NSUInteger i=0; i<byteArray.length; i++) {
		packet.data[i] = bytes[i];
	}
	
	return packet;
}

@end
