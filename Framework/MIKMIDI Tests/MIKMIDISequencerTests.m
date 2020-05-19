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
	// Test with negative number
	XCTAssertEqual([self.sequencer timeInSecondsForMusicTimeStamp:-1 options:MIKMIDISequencerTimeConversionOptionsNone], 0.0);

	XCTAssertEqualWithAccuracy([s timeInSecondsForMusicTimeStamp:3], [self.sequencer timeInSecondsForMusicTimeStamp:3 options:MIKMIDISequencerTimeConversionOptionsNone], 1e-6);

	MIKMIDITempoEvent *secondTempo = s.tempoEvents[1];
	MusicTimeStamp nextCheck = secondTempo.timeStamp+1;
    XCTAssertEqual([s timeInSecondsForMusicTimeStamp:nextCheck], [self.sequencer timeInSecondsForMusicTimeStamp:nextCheck options:MIKMIDISequencerTimeConversionOptionsNone]);

	MusicTimeStamp testTimeStamp = 850;
	NSTimeInterval expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	NSTimeInterval actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-13);

	// Test when tempo is overridden
	Float64 overrideTempo = 80.0;
	self.sequencer.tempo = overrideTempo;

	expected = 60 * testTimeStamp / overrideTempo;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	// Test while ignoring tempo override
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreTempoOverride];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	self.sequencer.tempo = 0; // Disable tempo override

	// Test with looping
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];

	testTimeStamp = 5; // Test before loop region, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 12; // Test inside loop region before first loop, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 37.5; // Test inside loop region after first loop, should be affected
	expected = 24.284925;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	[self.sequencer setLoopStartTimeStamp:200 endTimeStamp:600];

	testTimeStamp = 160; // Test before loop region, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 550; // Test inside loop region before first loop, should be unaffected
	expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp];
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 850; // Test inside loop region after first loop, should be affected
	expected = 427.46909;
	actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 850; // Test inside loop region after first loop, but ignoring looping should be affected
	NSTimeInterval withLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval ignoringLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	self.sequencer.loop = NO;
	NSTimeInterval withoutLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertNotEqualWithAccuracy(withLooping, ignoringLooping, 1e-12);
	XCTAssertEqualWithAccuracy(withoutLooping, ignoringLooping, 1e-12);

	// Test loop "unrolling"
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];
	testTimeStamp = 37.5; // Test inside loop region after first loop, should be affected
	NSTimeInterval withoutUnrolling = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsDontUnrollLoop];
	NSTimeInterval withUnrolling = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval expectedWithoutUnrolling = 8.094975;
	ignoringLooping = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	XCTAssertNotEqualWithAccuracy(withoutUnrolling, withUnrolling, 1e-12);
	XCTAssertNotEqualWithAccuracy(withUnrolling, ignoringLooping, 1e-12);
	XCTAssertEqualWithAccuracy(withoutUnrolling, expectedWithoutUnrolling, 1e-12);

	// Test with non-default rates
	for (NSNumber *rateNum in @[@0.9, @1.1, @2.0]) {
		float rate = rateNum.floatValue;
		self.sequencer.rate = rate;

		[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];

		testTimeStamp = 5; // Test before loop region
		expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp] / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		testTimeStamp = 12; // Test inside loop region before first loop
		expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp] / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		testTimeStamp = 37.5; // Test inside loop region after first loop
		expected = 24.284925 / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		[self.sequencer setLoopStartTimeStamp:200 endTimeStamp:600];

		testTimeStamp = 160; // Test before loop region
		expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp] / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		testTimeStamp = 550; // Test inside loop region before first loop
		expected = [s timeInSecondsForMusicTimeStamp:testTimeStamp] / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		testTimeStamp = 850; // Test inside loop region after first loop
		expected = 427.46909 / rate;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

		testTimeStamp = 850; // Test inside loop region after first loop while ignoring rate
		expected = 427.46909;
		actual = [self.sequencer timeInSecondsForMusicTimeStamp:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreRate];
		XCTAssertEqualWithAccuracy(expected, actual, 1e-12);
	}
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

	XCTAssertEqualWithAccuracy([s musicTimeStampForTimeInSeconds:3], [self.sequencer musicTimeStampForTimeInSeconds:3 options:MIKMIDISequencerTimeConversionOptionsNone], 1e-12);

	MIKMIDITempoEvent *secondTempo = s.tempoEvents[1];
	MusicTimeStamp nextCheckTimeStamp = secondTempo.timeStamp+1;
	NSTimeInterval nextCheck = [s timeInSecondsForMusicTimeStamp:nextCheckTimeStamp];
	XCTAssertEqualWithAccuracy(nextCheckTimeStamp, [self.sequencer musicTimeStampForTimeInSeconds:nextCheck options:MIKMIDISequencerTimeConversionOptionsNone], 1e-12);

	NSTimeInterval testTimeStamp = 400;
	MusicTimeStamp expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	MusicTimeStamp actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	// Test when tempo is overridden
	Float64 overrideTempo = 80.0;
	self.sequencer.tempo = overrideTempo;

	expected = overrideTempo * testTimeStamp / 60.0;
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	// Test while ignoring tempo override
	expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreTempoOverride];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	self.sequencer.tempo = 0; // Disable tempo override

	// Test with looping
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];

	testTimeStamp = 5; // Test before loop region, should be unaffected
	expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 8; // Test inside loop region before first loop, should be unaffected
	expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 37.5; // Test inside loop region after first loop, should be affected
	expected = 57.906294;
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	[self.sequencer setLoopStartTimeStamp:200 endTimeStamp:600];

	testTimeStamp = 160; // Test before loop region, should be unaffected
	expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 200; // Test inside loop region before first loop, should be unaffected
	expected = [s musicTimeStampForTimeInSeconds:testTimeStamp];
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-12);

	testTimeStamp = 450; // Test inside loop region after first loop, should be affected
	expected = 896.188353;
	actual = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertEqualWithAccuracy(expected, actual, 1e-6);

	testTimeStamp = 450; // Test inside loop region after first loop, but ignoring looping should be affected
	NSTimeInterval withLooping = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval ignoringLooping = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	self.sequencer.loop = NO;
	NSTimeInterval withoutLooping = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	XCTAssertNotEqualWithAccuracy(withLooping, ignoringLooping, 1e-12);
	XCTAssertEqualWithAccuracy(withoutLooping, ignoringLooping, 1e-12);

	// Test loop "unrolling"
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:10 endTimeStamp:15];
	testTimeStamp = 24.284925; // Test inside loop region after first loop, should be affected
	NSTimeInterval withoutUnrolling = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsDontUnrollLoop];
	NSTimeInterval withUnrolling = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsNone];
	NSTimeInterval expectedWithoutUnrolling = 12.5;
	ignoringLooping = [self.sequencer musicTimeStampForTimeInSeconds:testTimeStamp options:MIKMIDISequencerTimeConversionOptionsIgnoreLooping];
	XCTAssertNotEqualWithAccuracy(withoutUnrolling, withUnrolling, 1e-12);
	XCTAssertNotEqualWithAccuracy(withUnrolling, ignoringLooping, 1e-12);
	XCTAssertEqualWithAccuracy(withoutUnrolling, expectedWithoutUnrolling, 1e-12);
}

- (void)testTwoWayConversionBetweenMusicTimeStampAndSeconds
{
	NSBundle *bundle = [NSBundle bundleForClass:[self class]];
	NSURL *testMIDIFileURL = [bundle URLForResource:@"tempochanges" withExtension:@"mid"];
	NSError *error = nil;
	MIKMIDISequence *s = [MIKMIDISequence sequenceWithFileAtURL:testMIDIFileURL convertMIDIChannelsToTracks:NO error:&error];
	XCTAssertNotNil(s);
	self.sequencer.sequence = s;

	NSArray *testMusicTimeStamps = @[@3, @5, @12, @24.284925, @37.5, @57.906294, @160, @550, @850, @896.188353];

	// Test with default conversion options
	MIKMIDISequencerTimeConversionOptions options = MIKMIDISequencerTimeConversionOptionsNone;
	for (NSNumber *number in testMusicTimeStamps) {
		MusicTimeStamp timeStamp = [number doubleValue];
		NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
		MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
		NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
		XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
		XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
	}

	// Test with tempo override on
	self.sequencer.tempo = 80.0;
	for (NSNumber *number in testMusicTimeStamps) {
		MusicTimeStamp timeStamp = [number doubleValue];
		NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
		MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
		NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
		XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
		XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
	}

	// Test ignoring temp override
	options = MIKMIDISequencerTimeConversionOptionsIgnoreTempoOverride;
	for (NSNumber *number in testMusicTimeStamps) {
		MusicTimeStamp timeStamp = [number doubleValue];
		NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
		MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
		NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
		XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
		XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
	}

	// Test with non-default rates
	self.sequencer.tempo = 0;

	for (NSNumber *rateNum in @[@0.5, @0.9, @1.1, @2.0]) {
		self.sequencer.rate = rateNum.floatValue;
		options = MIKMIDISequencerTimeConversionOptionsNone;
		for (NSNumber *number in testMusicTimeStamps) {
			MusicTimeStamp timeStamp = [number doubleValue];
			NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
			MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
			NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
			XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
			XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
		}

		// Test ignoring rate
		options = MIKMIDISequencerTimeConversionOptionsIgnoreRate;
		for (NSNumber *number in testMusicTimeStamps) {
			MusicTimeStamp timeStamp = [number doubleValue];
			NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
			MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
			NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
			XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
			XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
		}

		// Test ignoring rate one-sided
		options = MIKMIDISequencerTimeConversionOptionsIgnoreRate;
		for (NSNumber *number in testMusicTimeStamps) {
			MusicTimeStamp timeStamp = [number doubleValue];
			NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
			MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:MIKMIDISequencerTimeConversionOptionsNone];
			NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
			XCTAssertNotEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
			XCTAssertNotEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
		}
	}

	// Test with looping
	self.sequencer.rate = 1.0;
	self.sequencer.loop = YES;
	[self.sequencer setLoopStartTimeStamp:200 endTimeStamp:600];
	options = MIKMIDISequencerTimeConversionOptionsNone;
	for (NSNumber *number in testMusicTimeStamps) {
		MusicTimeStamp timeStamp = [number doubleValue];
		NSTimeInterval timeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:timeStamp options:options];
		MusicTimeStamp convertedTimeStamp = [self.sequencer musicTimeStampForTimeInSeconds:timeInSeconds options:options];
		NSTimeInterval convertedTimeInSeconds = [self.sequencer timeInSecondsForMusicTimeStamp:convertedTimeStamp options:options];
		XCTAssertEqualWithAccuracy(timeStamp, convertedTimeStamp, 2e-6);
		XCTAssertEqualWithAccuracy(timeInSeconds, convertedTimeInSeconds, 2e-6);
	}
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
