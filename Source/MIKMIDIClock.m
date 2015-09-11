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
#error MIKMIDIClock.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIClock.m in the Build Phases for this target
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
@property (nonatomic) MusicTimeStamp lastSyncedMusicTimeStamp;

@property (nonatomic) Float64 musicTimeStampsPerMIDITimeStamp;
@property (nonatomic) Float64 midiTimeStampsPerMusicTimeStamp;

@property (nonatomic, strong) NSMutableDictionary *historicalClocks;
@property (nonatomic, strong) NSMutableOrderedSet *historicalClockMIDITimeStamps;

@property (nonatomic, getter=isReady) BOOL ready;

@property (nonatomic) dispatch_queue_t clockQueue;

@end


#pragma mark -
@implementation MIKMIDIClock

#pragma mark - Lifecycle

+ (instancetype)clock
{
	return [[self alloc] init];
}

- (instancetype)init
{
	return [self initWithQueue:YES];
}

- (instancetype)initWithQueue:(BOOL)createQueue
{
	if (self = [super init]) {
		if (createQueue) {
			NSString *queueLabel = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@".%@.%p", [self class], self];
			dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;

#if defined (__MAC_10_10) || defined (__IPHONE_8_0)
			if (&dispatch_queue_attr_make_with_qos_class != NULL) {
				attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, DISPATCH_QUEUE_PRIORITY_HIGH);
			}
#endif

			self.clockQueue = dispatch_queue_create(queueLabel.UTF8String, attr);
		}
	}
	return self;
}

#pragma mark - Queue

- (void)dispatchToClockQueue:(void (^)())block
{
	if (!block) return;

	dispatch_queue_t queue = self.clockQueue;
	if (queue) {
		dispatch_sync(queue, block);
	} else {
		block();
	}
}

#pragma mark - Time Stamps

- (void)syncMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withMIDITimeStamp:(MIDITimeStamp)midiTimeStamp tempo:(Float64)tempo
{
	[self dispatchToClockQueue:^{
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
				MIDITimeStamp oldTimeStamp = MIKMIDIGetCurrentTimeStamp() - MIKMIDIClockMIDITimeStampsPerTimeInterval(kDurationToKeepHistoricalClocks);
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
			MIKMIDIClock *historicalClock = [[MIKMIDIClock alloc] initWithQueue:NO];
			historicalClock.currentTempo = self.currentTempo;
			historicalClock.timeStampZero = self.timeStampZero;
			historicalClock.lastSyncedMIDITimeStamp = self.lastSyncedMIDITimeStamp;
			historicalClock.musicTimeStampsPerMIDITimeStamp = self.musicTimeStampsPerMIDITimeStamp;
			historicalClock.midiTimeStampsPerMusicTimeStamp = self.midiTimeStampsPerMusicTimeStamp;
			historicalClocks[midiTimeStampNumber] = historicalClock;
			[historicalClockMIDITimeStamps addObject:midiTimeStampNumber];
		}

		// Update new tempo and timing information
		Float64 secondsPerMIDITimeStamp = MIKMIDIClockSecondsPerMIDITimeStamp();
		Float64 secondsPerMusicTimeStamp = 60.0 / tempo;
		Float64 midiTimeStampsPerMusicTimeStamp = secondsPerMusicTimeStamp / secondsPerMIDITimeStamp;

		self.currentTempo = tempo;
		self.lastSyncedMIDITimeStamp = midiTimeStamp;
		self.lastSyncedMusicTimeStamp = musicTimeStamp;
		self.timeStampZero = midiTimeStamp - (musicTimeStamp * midiTimeStampsPerMusicTimeStamp);
		self.midiTimeStampsPerMusicTimeStamp = midiTimeStampsPerMusicTimeStamp;
		self.musicTimeStampsPerMIDITimeStamp = secondsPerMIDITimeStamp / secondsPerMusicTimeStamp;
		self.ready = YES;
	}];
}

- (void)unsyncMusicTimeStampsAndTemposFromMIDITimeStamps
{
	[self dispatchToClockQueue:^{
		self.ready = NO;
		self.currentTempo = 0;
		self.historicalClocks = nil;
		self.historicalClockMIDITimeStamps = nil;
	}];
}

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	__block MusicTimeStamp musicTimeStamp = 0;

	[self dispatchToClockQueue:^{
		if (!self.isReady) return;

		MIDITimeStamp lastSyncedMIDITimeStamp = self.lastSyncedMIDITimeStamp;
		if (midiTimeStamp >= lastSyncedMIDITimeStamp) {
			musicTimeStamp = [self musicTimeStampForMIDITimeStamp:midiTimeStamp withClock:self];
		} else {
			musicTimeStamp = [self musicTimeStampForMIDITimeStamp:midiTimeStamp withClock:[self clockForMIDITimeStamp:midiTimeStamp]];
		}
	}];

	return musicTimeStamp;
}

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp withClock:(MIKMIDIClock *)clock
{
	if (midiTimeStamp == clock.lastSyncedMIDITimeStamp) return clock.lastSyncedMusicTimeStamp;
	MIDITimeStamp timeStampZero = clock.timeStampZero;
	return (midiTimeStamp >= timeStampZero) ? ((midiTimeStamp - timeStampZero) * clock.musicTimeStampsPerMIDITimeStamp) : -((timeStampZero - midiTimeStamp) * clock.musicTimeStampsPerMIDITimeStamp);
}

- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	__block MIDITimeStamp midiTimeStamp = 0;

	[self dispatchToClockQueue:^{
		if (!self.isReady) return;
		if (musicTimeStamp == self.lastSyncedMusicTimeStamp) { midiTimeStamp = self.lastSyncedMIDITimeStamp; return; }

		midiTimeStamp = round(musicTimeStamp * self.midiTimeStampsPerMusicTimeStamp) + self.timeStampZero;

		if (midiTimeStamp < self.lastSyncedMIDITimeStamp) {
			NSDictionary *historicalClocks = self.historicalClocks;
			for (NSNumber *historicalClockTimeStamp in [[self.historicalClockMIDITimeStamps reverseObjectEnumerator] allObjects]) {
				MIKMIDIClock *clock = historicalClocks[historicalClockTimeStamp];
				MIDITimeStamp historicalMIDITimeStamp = round(musicTimeStamp * clock.midiTimeStampsPerMusicTimeStamp) + clock.timeStampZero;
				if (historicalMIDITimeStamp >= clock.lastSyncedMIDITimeStamp) {
					midiTimeStamp = historicalMIDITimeStamp;
					break;
				}
			}
		}
	}];

	return midiTimeStamp;
}

- (MIDITimeStamp)midiTimeStampsPerMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	__block MIDITimeStamp midiTimeStamps = 0;

	[self dispatchToClockQueue:^{
		if (self.isReady) midiTimeStamps = musicTimeStamp * self.midiTimeStampsPerMusicTimeStamp;
	}];

	return midiTimeStamps;
}

#pragma mark - Tempo

- (Float64)tempoAtMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	__block Float64 tempo = 0;

	[self dispatchToClockQueue:^{
		if (self.isReady) {
			if (midiTimeStamp >= self.lastSyncedMIDITimeStamp) {
				tempo = self.currentTempo;
			} else {
				tempo = [[self clockForMIDITimeStamp:midiTimeStamp] currentTempo];
			}
		}
	}];

	return tempo;
}

- (Float64)tempoAtMusicTimeStamp:(MusicTimeStamp)musicTimeStamp
{
	return [self tempoAtMIDITimeStamp:[self midiTimeStampForMusicTimeStamp:musicTimeStamp]];
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
	return MIKMIDIClockSecondsPerMIDITimeStamp();
}

+ (Float64)midiTimeStampsPerTimeInterval:(NSTimeInterval)timeInterval
{
	return MIKMIDIClockMIDITimeStampsPerTimeInterval(timeInterval);
}

Float64 MIKMIDIClockSecondsPerMIDITimeStamp()
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


Float64 MIKMIDIClockMIDITimeStampsPerTimeInterval(NSTimeInterval timeInterval)
{
	static Float64 midiTimeStampsPerSecond = 0;
	if (!midiTimeStampsPerSecond) midiTimeStampsPerSecond = (1.0 / MIKMIDIClockSecondsPerMIDITimeStamp());
	return midiTimeStampsPerSecond * timeInterval;
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
	if (selector == @selector(unsyncMusicTimeStampsAndTemposFromMIDITimeStamps)) return;
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