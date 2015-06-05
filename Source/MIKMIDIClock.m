//
//  MIKMIDIClock.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIClock.h"
#import "MIKMIDIUtilities.h"
#import <mach/mach_time.h>

#if !__has_feature(objc_arc)
#error MIKMIDIClock.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif


#define kDurationToKeepHistoricalClocks	1.0


#pragma mark -
@interface MIKMIDISyncedClockProxy : NSProxy
+ (instancetype)syncedClockWithClock:(MIKMIDIClock *)masterClock;
@property (readonly, nonatomic) MIKMIDIClock *masterClock;
@end


#pragma mark -
@interface MIKMIDIClock ()

@property (nonatomic) Float64 currentTempo;
@property (nonatomic) MIDITimeStamp timeStampZero;
@property (nonatomic) MIDITimeStamp lastSyncedMIDITimeStamp;

@property (nonatomic) Float64 musicTimeStampsPerMIDITimeStamp;
@property (nonatomic) Float64 midiTimeStampsPerMusicTimeStamp;

@property (nonatomic, strong) NSMutableDictionary *historicalClocks;
@property (nonatomic, strong) NSMutableOrderedSet *historicalClockMIDITimeStamps;

@property (nonatomic, getter=isReady) BOOL ready;

@end


#pragma mark -
@implementation MIKMIDIClock

#pragma mark - Lifecycle

+ (instancetype)clock
{
	return [[self alloc] init];
}

#pragma mark - Time Stamps

- (void)syncMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withMIDITimeStamp:(MIDITimeStamp)midiTimeStamp tempo:(Float64)tempo
{
	if (self.lastSyncedMIDITimeStamp) {
		// Add a clock to the historical clocks
		NSMutableDictionary *historicalClocks = self.historicalClocks;
		NSNumber *midiTimeStampNumber = @(midiTimeStamp);
		NSMutableOrderedSet *historicalClockMIDITimeStamps = self.historicalClockMIDITimeStamps;

		if (!historicalClocks) {
			historicalClocks = [NSMutableDictionary dictionary];
			self.historicalClocks = historicalClocks;
			self.historicalClockMIDITimeStamps = [NSMutableOrderedSet orderedSet];
		} else {
			// Remove clocks old enough to not be needed anymore
			MIDITimeStamp oldTimeStamp = MIKMIDIGetCurrentTimeStamp() - [MIKMIDIClock midiTimeStampsPerTimeInterval:kDurationToKeepHistoricalClocks];
			NSUInteger count = historicalClockMIDITimeStamps.count;
			NSMutableArray *timeStampsToRemove = [NSMutableArray array];
			NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
			for (NSUInteger i = 0; i < count; i++) {
				NSNumber *timeStampNumber = historicalClockMIDITimeStamps[i];
				MIDITimeStamp timeStamp = timeStampNumber.unsignedLongLongValue;
				if (timeStamp <= oldTimeStamp) {
					[timeStampsToRemove addObject:timeStampNumber];
					[indexesToRemove addIndex:i];
				} else {
					break;
				}
			}
			if (timeStampsToRemove.count) {
				[historicalClocks removeObjectsForKeys:timeStampsToRemove];
				[historicalClockMIDITimeStamps removeObjectsAtIndexes:indexesToRemove];
			}
		}

		// Add clock to history
		MIKMIDIClock *historicalClock = [MIKMIDIClock clock];
		historicalClock.currentTempo = self.currentTempo;
		historicalClock.timeStampZero = self.timeStampZero;
		historicalClock.lastSyncedMIDITimeStamp = self.lastSyncedMIDITimeStamp;
		historicalClock.musicTimeStampsPerMIDITimeStamp = self.musicTimeStampsPerMIDITimeStamp;
		historicalClock.midiTimeStampsPerMusicTimeStamp = self.midiTimeStampsPerMusicTimeStamp;
		historicalClocks[midiTimeStampNumber] = historicalClock;
		[historicalClockMIDITimeStamps addObject:midiTimeStampNumber];
	}

	// Update new tempo and timing information
	Float64 secondsPerMIDITimeStamp = [[self class] secondsPerMIDITimeStamp];
	Float64 secondsPerMusicTimeStamp = 60.0 / tempo;
	Float64 midiTimeStampsPerMusicTimeStamp = secondsPerMusicTimeStamp / secondsPerMIDITimeStamp;

	self.currentTempo = tempo;
	self.lastSyncedMIDITimeStamp = midiTimeStamp;
	self.timeStampZero = midiTimeStamp - (musicTimeStamp * midiTimeStampsPerMusicTimeStamp);
	self.midiTimeStampsPerMusicTimeStamp = midiTimeStampsPerMusicTimeStamp;
	self.musicTimeStampsPerMIDITimeStamp = secondsPerMIDITimeStamp / secondsPerMusicTimeStamp;
	self.ready = YES;
}

- (void)unsyncMusicTimeStampsTemposFromMIDITimeStamps
{
	self.ready = NO;
	self.currentTempo = 0;
	self.historicalClocks = nil;
	self.historicalClockMIDITimeStamps = nil;
}

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	if (!self.isReady) return 0;
	if (midiTimeStamp >= self.lastSyncedMIDITimeStamp) {
		return [self musicTimeStampForMIDITimeStamp:midiTimeStamp withClock:self];
	}

	return [self musicTimeStampForMIDITimeStamp:midiTimeStamp withClock:[self clockForMIDITimeStamp:midiTimeStamp]];
}

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp withClock:(MIKMIDIClock *)clock
{
	if (!self.isReady) return 0;
	MIDITimeStamp timeStampZero = clock.timeStampZero;
	return (midiTimeStamp >= timeStampZero) ? ((midiTimeStamp - timeStampZero) * clock.musicTimeStampsPerMIDITimeStamp) : -((timeStampZero - midiTimeStamp) * clock.musicTimeStampsPerMIDITimeStamp);
}

- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	if (!self.isReady) return 0;
	MIDITimeStamp midiTimeStamp = round(musicTimeStamp * self.midiTimeStampsPerMusicTimeStamp) + self.timeStampZero;
	if (midiTimeStamp >= self.lastSyncedMIDITimeStamp) return midiTimeStamp;

	NSDictionary *historicalClocks = self.historicalClocks;
	for (NSNumber *historicalClockTimeStamp in [[self.historicalClockMIDITimeStamps reverseObjectEnumerator] allObjects]) {
		MIKMIDIClock *clock = historicalClocks[historicalClockTimeStamp];
		MIDITimeStamp historicalMIDITimeStamp = round(musicTimeStamp * clock.midiTimeStampsPerMusicTimeStamp) + clock.timeStampZero;
		if (historicalMIDITimeStamp >= clock.lastSyncedMIDITimeStamp) return historicalMIDITimeStamp;
	}

	return midiTimeStamp;
}

- (MIDITimeStamp)midiTimeStampsPerMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	return self.isReady ? (musicTimeStamp * self.midiTimeStampsPerMusicTimeStamp) : 0;
}

#pragma mark - Tempo

- (Float64)tempoAtMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	if (!self.isReady) return 0;
	if (midiTimeStamp >= self.lastSyncedMIDITimeStamp) return self.currentTempo;
	return [[self clockForMIDITimeStamp:midiTimeStamp] currentTempo];
}

- (Float64)tempoAtMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	return self.isReady ? [self tempoAtMIDITimeStamp:[self midiTimeStampForMusicTimeStamp:musicTimeStamp]] : 0;
}

#pragma mark - Historical Clocks

- (MIKMIDIClock *)clockForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	MIKMIDIClock *clock = self;
	NSDictionary *historicalClocks = self.historicalClocks;
	for (NSNumber *historicalClockTimeStamp in [[self.historicalClockMIDITimeStamps reverseObjectEnumerator] allObjects]) {
		if ([historicalClockTimeStamp unsignedLongLongValue] > midiTimeStamp) {
			clock = historicalClocks[historicalClockTimeStamp];
		} else {
			break;
		}
	}
	return clock;
}

#pragma mark - Synced Clock

- (MIKMIDIClock *)syncedClock
{
	return (MIKMIDIClock *)[MIKMIDISyncedClockProxy syncedClockWithClock:self];
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

#pragma mark - Deprecated Methods

- (void)setMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withTempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	[self syncMusicTimeStamp:musicTimeStamp withMIDITimeStamp:midiTimeStamp tempo:tempo];
}

@end


#pragma mark -
@implementation MIKMIDISyncedClockProxy

+ (instancetype)syncedClockWithClock:(MIKMIDIClock *)masterClock
{
	MIKMIDISyncedClockProxy *proxy = [self alloc];
	proxy->_masterClock = masterClock;
	return proxy;
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
	SEL selector = invocation.selector;
	if (selector == @selector(syncMusicTimeStamp:withMIDITimeStamp:tempo:)) return;
	if (selector == @selector(unsyncMusicTimeStampsTemposFromMIDITimeStamps)) return;
	if (selector == @selector(setMusicTimeStamp:withTempo:atMIDITimeStamp:)) return;	// deprecated

	if (selector == @selector(syncedClock)) {
		MIKMIDISyncedClockProxy *syncedClock = self;
		return [invocation setReturnValue:&syncedClock];
	}

	[invocation invokeWithTarget:self.masterClock];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
	return [self.masterClock methodSignatureForSelector:sel];
}

@end