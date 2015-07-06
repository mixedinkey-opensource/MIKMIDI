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

@property (nonatomic, strong) MIKMIDISequence *sequence;
@property (nonatomic, strong) NSMutableSet *receivedNotificationKeyPaths;

@end

@implementation MIKMIDISequenceTests

- (void)setUp
{
    [super setUp];
	
	self.receivedNotificationKeyPaths = [NSMutableSet set];
	self.sequence = [MIKMIDISequence sequence];
	[self.sequence addObserver:self forKeyPath:@"tracks" options:0 context:NULL];
	[self.sequence addObserver:self forKeyPath:@"durationInSeconds" options:0 context:NULL];
	[self.sequence addObserver:self forKeyPath:@"length" options:0 context:NULL];
}

- (void)tearDown
{
	[self.sequence removeObserver:self forKeyPath:@"tracks"];
	[self.sequence removeObserver:self forKeyPath:@"durationInSeconds"];
	[self.sequence removeObserver:self forKeyPath:@"length"];
	
	self.sequence = nil;
	
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

- (void)testKVOForAddingATrack
{
	XCTAssertNotNil(self.sequence);
	
	MIKMIDITrack *firstTrack = [self.sequence addTrack];
	XCTAssertNotNil(firstTrack, @"Creating an MIKMIDITrack failed.");
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"tracks"], @"KVO notification when adding a track not received.");
}

- (void)testKVOForRemovingATrack
{
	MIKMIDITrack *firstTrack = [self.sequence addTrack];
	XCTAssertNotNil(firstTrack, @"Creating an MIKMIDITrack failed.");
	MIKMIDITrack *secondTrack = [self.sequence addTrack];
	XCTAssertNotNil(secondTrack, @"Creating an MIKMIDITrack failed.");

	[self.receivedNotificationKeyPaths removeAllObjects];
	[self.sequence removeTrack:firstTrack];
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"tracks"], @"KVO notification when removing a track not received.");
	XCTAssertEqualObjects(self.sequence.tracks, @[secondTrack], @"Removing a track failed.");
}

- (void)testLength
{
	MIKMIDITrack *firstTrack = [self.sequence addTrack];
	XCTAssertNotNil(firstTrack, @"Creating an MIKMIDITrack failed.");
	MIKMIDITrack *secondTrack = [self.sequence addTrack];
	XCTAssertNotNil(secondTrack, @"Creating an MIKMIDITrack failed.");
	MIKMIDITrack *thirdTrack = [self.sequence addTrack];
	XCTAssertNotNil(thirdTrack, @"Creating an MIKMIDITrack failed.");

	self.sequence.length = MIKMIDISequenceLongestTrackLength;
	
	[self.receivedNotificationKeyPaths removeAllObjects];
	[thirdTrack addEvent:[MIKMIDINoteEvent noteEventWithTimeStamp:100 note:60 velocity:127 duration:1 channel:0]];
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"length"], @"KVO notification for length failed after adding event to child track.");
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"durationInSeconds"], @"KVO notification for durationInSeconds failed after adding event to child track.");
	
	[self.receivedNotificationKeyPaths removeAllObjects];
	[thirdTrack removeAllEvents];
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"length"], @"KVO notification for length failed after removing events from child track.");
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"durationInSeconds"], @"KVO notification for durationInSeconds failed after removing events from child track.");
	
	[thirdTrack addEvent:[MIKMIDINoteEvent noteEventWithTimeStamp:100 note:60 velocity:127 duration:1 channel:0]];
	[self.receivedNotificationKeyPaths removeAllObjects];
	[self.sequence removeTrack:thirdTrack];
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"length"], @"KVO notification for length failed after removing longest child track.");
	XCTAssertTrue([self.receivedNotificationKeyPaths containsObject:@"durationInSeconds"], @"KVO notification for durationInSeconds failed after removing longest child track.");
}

- (void)testSetTimeSignature
{
	[self.sequence setTimeSignature:MIKMIDITimeSignatureMake(2, 4) atTimeStamp:0];
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (object == self.sequence) {
		[self.receivedNotificationKeyPaths addObject:keyPath];
	}
}

@end
