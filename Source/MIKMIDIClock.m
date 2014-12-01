//
//  MIKMIDIClock.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIClock.h"

@interface MIKMIDIClock ()
@property (nonatomic) MIDITimeStamp timeStampZero;
@property (nonatomic) Float64 musicTimeStampsPerMIDITimeStamp;
@property (nonatomic) Float64 midiTimeStampsPerMusicTimeStamp;
@end


@implementation MIKMIDIClock

#pragma mark - Lifecycle

+ (instancetype)clock
{
	return [[self alloc] init];
}

#pragma mark - Time Stamps

- (void)setMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withTempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	Float64 secondsPerMIDITimeStamp = [[self class] secondsPerMIDITimeStamp];
	Float64 secondsPerMusicTimeStamp = 1.0 / (tempo / 60.0);
	Float64 musicTimeStampsPerMIDITimeStamp = secondsPerMIDITimeStamp / secondsPerMusicTimeStamp;

	self.timeStampZero = midiTimeStamp - (musicTimeStamp * musicTimeStampsPerMIDITimeStamp);
	self.midiTimeStampsPerMusicTimeStamp = secondsPerMusicTimeStamp / secondsPerMIDITimeStamp;
	self.musicTimeStampsPerMIDITimeStamp = musicTimeStampsPerMIDITimeStamp;
}

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	return (midiTimeStamp - self.timeStampZero) * self.musicTimeStampsPerMIDITimeStamp;
}

- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	return (musicTimeStamp * self.midiTimeStampsPerMusicTimeStamp) + self.timeStampZero;
}

#pragma mark - Class Methods

+ (Float64)secondsPerMIDITimeStamp
{
	static Float64 secondsPerMIDITimeStamp;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		mach_timebase_info_data_t timeBaseInfoData;
		mach_timebase_info(&timeBaseInfoData);
		secondsPerMIDITimeStamp = (timeBaseInfoData.numer / timeBaseInfoData.denom) / 1.0e9;
	});
	return secondsPerMIDITimeStamp;
}

+ (Float64)midiTimeStampsPerTimeInterval:(NSTimeInterval)timeInterval
{
	return (1.0 / [self secondsPerMIDITimeStamp]) * timeInterval;
}

@end
