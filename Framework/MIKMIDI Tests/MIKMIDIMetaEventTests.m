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
}

@end
