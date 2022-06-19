//
//  MIKMIDIEventCachingTests.m
//  MIKMIDI Tests
//
//  Created by Andrew R Madsen on 11/4/19.
//  Copyright © 2019 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIEventCachingTests : XCTestCase

@property (nonatomic, strong) MIKMIDISequence *sequence;

@end

@implementation MIKMIDIEventCachingTests

- (void)setUp
{
	MIKMIDISequence *sequence = [MIKMIDISequence sequence];
	MIKMIDITrack *tempoTrack = sequence.tempoTrack;
	for (NSInteger i=0; i<300; i++) {
		Float64 tempo = arc4random_uniform(200);
		MIKMIDITempoEvent *tempoEvent = [MIKMIDITempoEvent tempoEventWithTimeStamp:i tempo:tempo];
		[tempoTrack addEvent:tempoEvent];
	}
	self.sequence = sequence;
}

- (void)testTempoEventsPerformance {
    // This is an example of a performance test case.
    [self measureBlock:^{
		for (NSInteger i=0; i<5000; i++) {
			NSArray *tempoEvents = [self.sequence tempoEvents];
			[tempoEvents self];
		}
    }];
}

@end
