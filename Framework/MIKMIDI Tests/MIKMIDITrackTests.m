//
//  MIKMIDITrackTests.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/7/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDITrackTests : XCTestCase

@property BOOL eventsChangeNotificationReceived;

@end

@implementation MIKMIDITrackTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testBasicEventsAddRemove
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *track = [sequence addTrack];
	
	[track addObserver:self forKeyPath:@"events" options:0 context:NULL];
	{
		// Test adding an event
		MIKMIDIEvent *event = [MIKMIDINoteEvent noteEventWithTimeStamp:1 note:60 velocity:127 duration:1 channel:0];
		[track addEvent:event];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Adding an event to MIKMIDITrack did not produce a KVO notification.");
		XCTAssertTrue([track.events containsObject:event], @"Adding an event to MIKMIDITrack failed.");
		XCTAssertEqual([track.events count], 1, @"Adding an event to MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing an event
		[track removeEvent:event];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing an event from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertFalse([track.events containsObject:event], @"Removing an event from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing some events
		MIKMIDIEvent *event2 = [MIKMIDINoteEvent noteEventWithTimeStamp:2 note:61 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *event3 = [MIKMIDINoteEvent noteEventWithTimeStamp:4 note:62 velocity:127 duration:1 channel:0];
		MIKMIDIEvent *event4 = [MIKMIDINoteEvent noteEventWithTimeStamp:6 note:63 velocity:127 duration:1 channel:0];
		[track addEvent:event];
		[track addEvent:event2];
		[track addEvent:event3];
		[track addEvent:event4];
		XCTAssertEqual([track.events count], 4, @"Adding 4 events to MIKMIDITrack failed.");
		[track removeEvents:@[event2, event3]];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing some events from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertEqual([track.events count], 2, @"Removing some events from MIKMIDITrack failed.");
		NSArray *remainingEvents = @[event, event4];
		XCTAssertEqualObjects(remainingEvents, track.events, @"Removing some events from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
		
		// Test removing all events
		[track addEvent:event];
		[track addEvent:event2];
		[track addEvent:event3];
		[track removeAllEvents];
		XCTAssertTrue(self.eventsChangeNotificationReceived, @"Removing all events from MIKMIDITrack did not produce a KVO notification.");
		XCTAssertEqual([track.events count], 0, @"Removing all events from MIKMIDITrack failed.");
		self.eventsChangeNotificationReceived = NO;
	}
	[track removeObserver:self forKeyPath:@"events"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([object isKindOfClass:[MIKMIDITrack class]] && [keyPath isEqualToString:@"events"]) {
		self.eventsChangeNotificationReceived = YES;
	}
}

@end
