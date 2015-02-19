//
//  MIKMIDIClock.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIClock.h"
#import <mach/mach_time.h>

#if !__has_feature(objc_arc)
#error MIKMIDIClock.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

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
	Float64 midiTimeStampsPerMusicTimeStamp = secondsPerMusicTimeStamp / secondsPerMIDITimeStamp;

	self.timeStampZero = midiTimeStamp - (musicTimeStamp * midiTimeStampsPerMusicTimeStamp);
	self.midiTimeStampsPerMusicTimeStamp = midiTimeStampsPerMusicTimeStamp;
	self.musicTimeStampsPerMIDITimeStamp = secondsPerMIDITimeStamp / secondsPerMusicTimeStamp;
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

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIClock *clock = [[[self class] alloc] init];
	clock.timeStampZero = self.timeStampZero;
	clock.musicTimeStampsPerMIDITimeStamp = self.musicTimeStampsPerMIDITimeStamp;
	clock.midiTimeStampsPerMusicTimeStamp = self.midiTimeStampsPerMusicTimeStamp;
	return clock;
}

@end
