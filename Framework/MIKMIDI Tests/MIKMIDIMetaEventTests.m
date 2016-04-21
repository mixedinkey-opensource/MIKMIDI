//
//  MIKMIDIMetaEventTests.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 4/21/16.
//  Copyright © 2016 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIMetaEventTests : XCTestCase

@end

@implementation MIKMIDIMetaEventTests

- (void)testMetaEventInit
{
	NSString *text = @"Mixed In Key";
	MIKMIDIMetaTextEvent *textEvent =
	(MIKMIDIMetaTextEvent *)[[MIKMIDIMetaEvent alloc] initWithMetaData:[text dataUsingEncoding:NSUTF8StringEncoding]
														  metadataType:MIKMIDIMetaEventTypeTextEvent
															 timeStamp:10];
	XCTAssertTrue([textEvent isMemberOfClass:[MIKMIDIMetaTextEvent class]], @"MIKMIDIMetaEvent initializer didn't produce expected subclass (MIKMIDIMetaTextEvent)");
	XCTAssertEqualObjects(textEvent.string, text, @"MIKMIDIMetaTextEvent didn't have expected string value.");
	XCTAssertEqual(textEvent.metadataType, MIKMIDIMetaEventTypeTextEvent, "MIKMIDIMetaTextEvent didn't have expected metadataType.");
	XCTAssertEqual(textEvent.timeStamp, 10, "MIKMIDIMetaTextEvent didn't have expected timeStamp.");
}

- (void)testMetaTextEventInit
{
	NSString *text = @"Mixed In Key";
	MIKMIDIMetaTextEvent *textEvent = [[MIKMIDIMetaTextEvent alloc] initWithString:text timeStamp:27];
	XCTAssertTrue([textEvent isMemberOfClass:[MIKMIDIMetaTextEvent class]], @"MIKMIDIMetaTextEvent initializer didn't produce expected subclass (MIKMIDIMetaTextEvent)");
	XCTAssertEqualObjects(textEvent.string, text, @"MIKMIDIMetaTextEvent didn't have expected string value.");
	XCTAssertEqual(textEvent.metadataType, MIKMIDIMetaEventTypeTextEvent, "MIKMIDIMetaTextEvent didn't have expected metadataType.");
	XCTAssertEqual(textEvent.timeStamp, 27, "MIKMIDIMetaTextEvent didn't have expected timeStamp.");
}

- (void)testMetaTrackSequenceNameEventInit
{
	NSString *name = @"Have You Heard?";
	MIKMIDIMetaTrackSequenceNameEvent *nameEvent =
	[[MIKMIDIMetaTrackSequenceNameEvent alloc] initWithName:name timeStamp:42];
	
	XCTAssertTrue([nameEvent isMemberOfClass:[MIKMIDIMetaTrackSequenceNameEvent class]], @"MIKMIDIMetaTrackSequenceNameEvent initializer didn't produce expected subclass (MIKMIDIMetaTrackSequenceNameEvent)");
	XCTAssertEqualObjects(nameEvent.name, name, @"MIKMIDIMetaTrackSequenceNameEvent didn't have expected string value.");
	XCTAssertEqual(nameEvent.metadataType, MIKMIDIMetaEventTypeTrackSequenceName, "MIKMIDIMetaTrackSequenceNameEvent didn't have expected metadataType.");
	XCTAssertEqual(nameEvent.timeStamp, 42, "MIKMIDIMetaTrackSequenceNameEvent didn't have expected timeStamp.");
}

@end
