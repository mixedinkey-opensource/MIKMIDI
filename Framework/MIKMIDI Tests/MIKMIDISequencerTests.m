//
//  MIKMIDISequencerTests.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/13/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDISequencerTests : XCTestCase

@property (nonatomic, strong) MIKMIDISequencer *sequencer;

@end

@implementation MIKMIDISequencerTests

- (void)setUp
{
	[super setUp];
	
	self.sequencer = [MIKMIDISequencer sequencer];
}

- (void)tearDown
{
	[super tearDown];
}

- (void)testConversionFromMusicTimeStampToSeconds
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"tempochanges" withExtension:@"mid"];
	NSError *error = nil;
	MIKMIDISequence *s = [MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:&error];
	XCTAssertNotNil(s);
	self.sequencer.sequence = s;

	XCTAssertEqual([self.sequencer timeInSecondsForMusicTimeStamp:0 options:MIKMIDISequencerTimeConversionOptionsNone], 0.0);

	XCTAssertEqualWithAccuracy([s timeInSecondsForMusicTimeStamp:3], [self.sequencer timeInSecondsForMusicTimeStamp:3 options:MIKMIDISequencerTimeConversionOptionsNone], 1e-6 );

	MIKMIDITempoEvent *secondTempo = s.tempoEvents[1];
	MusicTimeStamp nextCheck = secondTempo.timeStamp+1;
	XCTAssertEqualWithAccuracy([s timeInSecondsForMusicTimeStamp:nextCheck], [self.sequencer timeInSecondsForMusicTimeStamp:nextCheck options:MIKMIDISequencerTimeConversionOptionsNone], 1e-6);

	MusicTimeStamp testTimeStamp = 850;
	NSTimeInterval expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	NSTimeInterval actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	// Test when tempo is overridden
	Float64 overrideTempo = 80.0;
	self.sequencer.tempo = overrideTempo;

	expected = 60 * testTimeStamp / overrideTempo;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	self.sequencer.tempo = 0; // Disable tempo override

	// Test with looping
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];

	testTimeStamp = 5; // Test before loop region, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 12; // Test inside loop region before first loop, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 37.5; // Test inside loop region after first loop, should be affected
	expected = 24.284925;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	[self.sequencer setLoopStartTimeStamp:200 endTimeStamp:600];

	testTimeStamp = 160; // Test before loop region, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 550; // Test inside loop region before first loop, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 850; // Test inside loop region after first loop, should be affected
	expected = 427.46909;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 850; // Test inside loop region after first loop, but ignoring looping should be affected
	NSTimeInterval withLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval ignoringLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	self.sequencer.loop = NO;
	NSTimeInterval withoutLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertNotEqualWithAccuracy(withLooping, ignoringLooping, 1e-6);
	XCTAssertEqualWithAccuracy(withoutLooping, ignoringLooping, 1e-6);

	// Test loop "unrolling"
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];
	testTimeStamp = 37.5; // Test inside loop region after first loop, should be affected
	NSTimeInterval withoutUnrolling = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsDontUnrollLoop];
	NSTimeInterval withUnrolling = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval expectedWithoutUnrolling = 8.094975;
	ignoringLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	XCTAssertNotEqualWithAccuracy(withoutUnrolling, withUnrolling, 1e-6);
	XCTAssertNotEqualWithAccuracy(withUnrolling, ignoringLooping, 1e-6);
	XCTAssertEqualWithAccuracy(withoutUnrolling, expectedWithoutUnrolling, 1e-6);
}

- (void)testConversionFromSecondsToMusicTimeStamp
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"tempochanges" withExtension:@"mid"];
	NSError *error = nil;
	MIKMIDISequence *s = [MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:&error];
	XCTAssertNotNil(s);
	self.sequencer.sequence = s;

	XCTAssertEqual([self.sequencer musicTimeStampForTimeInSeconds:0.0 options:MIKMIDISequencerTimeConversionOptionsNone], 0);
}

- (void)testBuiltinSynthesizers
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"bach" withExtension:@"mid"];
	NSError *error = nil;
	MIKMIDISequence *sequence = [MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:&error];
	XCTAssertNotNil(sequence);
	
	self.sequencer.sequence = sequence;
	for (MIKMIDITrack *track in sequence.tracks) {
		MIKMIDISynthesizer *synth = [self.sequencer builtinSynthesizerForTrack:track];
		XCTAssertNotNil(synth, @"-builtinSynthesizerForTrack: test failed, because it returned nil.");
	}
}

@end
