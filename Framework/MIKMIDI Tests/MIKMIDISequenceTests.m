//
//  MIKMIDISequenceTests.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/7/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDISequenceTests : XCTestCase

@end

@implementation MIKMIDISequenceTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMIDIFileRead
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"bach" withExtension:@"mid"];
	NSError *error = nil;
	MIKMIDISequence *sequence = [MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:&error];
	XCTAssertNotNil(sequence);
	
	// Make sure number of tracks is correct
	XCTAssertEqual([sequence.tracks count], 3);
	XCTAssertNotNil(sequence.tempoTrack);
	
	// Check that the number of events in each track is correct
	XCTAssertEqual([[sequence.tracks[1] events] count], 242);
	XCTAssertEqual([[sequence.tracks[2] events] count], 220);
}

- (void)testMIDIFileReadPerformance
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"Parallax-Loader" withExtension:@"mid"];
	[self measureBlock:^{
		[MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:NULL];
	}];
}

@end
