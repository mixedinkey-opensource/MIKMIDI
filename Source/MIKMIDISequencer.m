//
//  MIKMIDISequencer.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequencer.h"
#import "MIKMIDISequence.h"
#import "MIKMIDITrack.h"
#import "MIKMIDIClock.h"
#import "MIKMIDITempoEvent.h"
#import "MIKMIDINoteEvent.h"
#import "MIKMIDINoteOnCommand.h"
#import "MIKMIDINoteOffCommand.h"
#import "MIKMIDIDeviceManager.h"


#define MIKMIDISequencerDefaultTempo	120


#pragma mark -

@interface MIKMIDIEventWithDestination : NSObject
@property (strong, nonatomic) MIKMIDIEvent *event;
@property (strong, nonatomic) MIKMIDIDestinationEndpoint *destination;
+ (instancetype)eventWithDestination:(MIKMIDIDestinationEndpoint *)destination event:(MIKMIDIEvent *)event;
@end


@interface MIKMIDICommandWithDestination : NSObject
@property (strong, nonatomic) MIKMIDICommand *command;
@property (strong, nonatomic) MIKMIDIDestinationEndpoint *destination;
+ (instancetype)commandWithDestination:(MIKMIDIDestinationEndpoint *)destination command:(MIKMIDICommand *)command;
@end



#pragma mark -

@interface MIKMIDISequencer ()

@property (readonly, nonatomic) MIKMIDIClock *clock;

@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (nonatomic, getter=isLooping) BOOL looping;

@property (nonatomic) MIDITimeStamp lastProcessedMIDITimeStamp;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSMutableDictionary *pendingNoteOffs;
@property (strong, nonatomic) NSMutableOrderedSet *pendingNoteOffMIDITimeStamps;

@property (strong, nonatomic) NSMutableDictionary *historicalClocks;
@property (strong, nonatomic) NSMutableOrderedSet *historicalClockMIDITimeStamps;

@property (strong, nonatomic) NSMutableDictionary *pendingRecordedNoteEvents;

@end


@implementation MIKMIDISequencer

#pragma mark - Lifecycle

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence
{
	if (self = [super init]) {
		_sequence = sequence;
		_clock = [MIKMIDIClock clock];
	}
	return self;
}

+ (instancetype)sequencerWithSequence:(MIKMIDISequence *)sequence
{
	return [[self alloc] initWithSequence:sequence];
}

- (instancetype)init
{
	return [self initWithSequence:[MIKMIDISequence sequence]];
}

+ (instancetype)sequencer
{
	return [[self alloc] init];
}

#pragma mark - Playback

- (void)startPlayback
{
	[self startPlaybackAtTimeStamp:0];
}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp
{
	MIDITimeStamp midiTimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.001];
	[self startPlaybackAtTimeStamp:timeStamp MIDITimeStamp:midiTimeStamp];
}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	if (self.isPlaying) [self stopRecording];

	Float64 startingTempo;
	if (![self.sequence getTempo:&startingTempo atTimeStamp:timeStamp]) startingTempo = MIKMIDISequencerDefaultTempo;
	[self updateClockWithMusicTimeStamp:timeStamp tempo:startingTempo atMIDITimeStamp:midiTimeStamp];

	self.playing = YES;
	self.pendingNoteOffs = [NSMutableDictionary dictionary];
	self.pendingNoteOffMIDITimeStamps = [NSMutableOrderedSet orderedSet];
	self.lastProcessedMIDITimeStamp = midiTimeStamp - 1;
	self.timer = [NSTimer timerWithTimeInterval:0.05 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	[self.timer fire];
}

- (void)resumePlayback
{
	[self startPlaybackAtTimeStamp:self.currentTimeStamp];
}

- (void)stopPlayback
{
	if (!self.isPlaying) return;

	[self.timer invalidate];
	self.timer = nil;
	[self sendPendingNoteOffCommandsUpToMIDITimeStamp:0];
	self.pendingNoteOffs = nil;
	self.pendingNoteOffMIDITimeStamps = nil;
	self.historicalClocks = nil;
	self.historicalClockMIDITimeStamps = nil;
	self.looping = NO;
	[self currentTimeStamp];	// update the current time stamp
	self.playing = NO;
}

- (void)processSequenceStartingFromMIDITimeStamp:(MIDITimeStamp)fromMIDITimeStamp
{
	MIDITimeStamp toMIDITimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.1];
	if (toMIDITimeStamp < fromMIDITimeStamp) return;
	MIKMIDIClock *clock = self.clock;

	MIKMIDISequence *sequence = self.sequence;
	MusicTimeStamp loopStartTimeStamp = self.loopStartTimeStamp;
	MusicTimeStamp loopEndTimeStamp = self.loopEndTimeStamp;
	MusicTimeStamp fromMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:fromMIDITimeStamp];
	MusicTimeStamp calculatedToMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:toMIDITimeStamp];
	if (self.shouldLoop && !self.isLooping && calculatedToMusicTimeStamp > loopStartTimeStamp) self.looping = YES;
	BOOL isLooping = self.isLooping;

	MusicTimeStamp maxMusicTimeStamp;
	if (isLooping) {
		maxMusicTimeStamp = loopEndTimeStamp;
	} else {
		maxMusicTimeStamp = self.isRecording ? DBL_MAX : sequence.length;
	}

	MusicTimeStamp toMusicTimeStamp = MIN(calculatedToMusicTimeStamp, maxMusicTimeStamp);

	// Send pending note off commands
	MIDITimeStamp actualToMIDITimeStamp = [clock midiTimeStampForMusicTimeStamp:toMusicTimeStamp];
	[self sendPendingNoteOffCommandsUpToMIDITimeStamp:actualToMIDITimeStamp];

	// Get relevant tempo events
	NSMutableDictionary *tempoEvents = [NSMutableDictionary dictionary];
	NSMutableDictionary *timeStampEvents = [NSMutableDictionary dictionary];
	for (MIKMIDITempoEvent *tempoEvent in [sequence.tempoTrack eventsOfClass:[MIKMIDITempoEvent class] fromTimeStamp:fromMusicTimeStamp toTimeStamp:toMusicTimeStamp]) {
		NSNumber *timeStampKey = @(tempoEvent.timeStamp);
		timeStampEvents[timeStampKey] = [NSMutableArray arrayWithObject:tempoEvent];
		tempoEvents[timeStampKey] = tempoEvent;
	}

	// Get other events
	for (MIKMIDITrack *track in sequence.tracks) {
		MIKMIDIDestinationEndpoint *destination = track.destinationEndpoint;
		for (MIKMIDIEvent *event in [track eventsFromTimeStamp:fromMusicTimeStamp toTimeStamp:toMusicTimeStamp]) {
			NSNumber *timeStampKey = @(event.timeStamp);
			NSMutableArray *eventsAtTimeStamp = timeStampEvents[timeStampKey] ? timeStampEvents[timeStampKey] : [NSMutableArray array];
			[eventsAtTimeStamp addObject:[MIKMIDIEventWithDestination eventWithDestination:destination event:event]];
			timeStampEvents[timeStampKey] = eventsAtTimeStamp;
		}
	}

	// Schedule events
	MIDITimeStamp lastProcessedMIDITimeStamp = fromMIDITimeStamp;
	for (NSNumber *timeStampKey in [timeStampEvents.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
		MusicTimeStamp musicTimeStamp = timeStampKey.doubleValue;
		if (isLooping && (musicTimeStamp < loopStartTimeStamp || musicTimeStamp >= loopEndTimeStamp)) continue;
		MIDITimeStamp midiTimeStamp = [clock midiTimeStampForMusicTimeStamp:musicTimeStamp];
		MIKMIDITempoEvent *tempoEventAtTimeStamp = tempoEvents[timeStampKey];
		if (tempoEventAtTimeStamp) [self updateClockWithMusicTimeStamp:musicTimeStamp tempo:tempoEventAtTimeStamp.bpm atMIDITimeStamp:midiTimeStamp];

		NSArray *events = timeStampEvents[timeStampKey];
		for (id eventObject in events) {
			if ([eventObject isKindOfClass:[MIKMIDIEventWithDestination class]]) {
				[self scheduleEventWithDestination:eventObject atMIDITimeStamp:midiTimeStamp];
			}
		}

		lastProcessedMIDITimeStamp = midiTimeStamp;
	}

	self.lastProcessedMIDITimeStamp = lastProcessedMIDITimeStamp;

	if (isLooping) {
		if (calculatedToMusicTimeStamp > toMusicTimeStamp) {
			Float64 tempo;
			if (![sequence getTempo:&tempo atTimeStamp:loopStartTimeStamp]) tempo = MIKMIDISequencerDefaultTempo;
			MusicTimeStamp loopLength = loopEndTimeStamp - loopStartTimeStamp;

			MIDITimeStamp loopStartMIDITimeStamp = [clock midiTimeStampForMusicTimeStamp:loopStartTimeStamp + loopLength];
			[self updateClockWithMusicTimeStamp:loopStartTimeStamp tempo:tempo atMIDITimeStamp:loopStartMIDITimeStamp];
			[self processSequenceStartingFromMIDITimeStamp:loopStartMIDITimeStamp];
		}
	} else {
		MIDITimeStamp systemTimeStamp = MIKMIDIGetCurrentTimeStamp();
		if ((systemTimeStamp > lastProcessedMIDITimeStamp) && ([clock musicTimeStampForMIDITimeStamp:systemTimeStamp] >= sequence.length)) {
			[self stopRecording];
		}
	}
}

- (void)scheduleEventWithDestination:(MIKMIDIEventWithDestination *)destinationEvent atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	MIKMIDIEvent *event = destinationEvent.event;
	MIKMIDIDestinationEndpoint *destination = destinationEvent.destination;
	NSMutableArray *commands = [NSMutableArray array];
	NSMutableDictionary *pendingNoteOffs = self.pendingNoteOffs;
	NSMutableOrderedSet *pendingNoteOffTimeStamps = self.pendingNoteOffMIDITimeStamps;

	if ([event isKindOfClass:[MIKMIDINoteEvent class]]) {
		// Note On
		MIKMIDINoteEvent *noteEvent = (MIKMIDINoteEvent *)event;
		MIKMutableMIDINoteOnCommand *noteOn = [MIKMutableMIDINoteOnCommand commandForCommandType:MIKMIDICommandTypeNoteOn];
		noteOn.midiTimestamp = midiTimeStamp;
		noteOn.channel = noteEvent.channel;
		noteOn.note = noteEvent.note;
		noteOn.velocity = noteEvent.velocity;
		[commands addObject:noteOn];

		// Note Off
		MIKMutableMIDINoteOffCommand *noteOff = [MIKMutableMIDINoteOffCommand commandForCommandType:MIKMIDICommandTypeNoteOff];
		MIDITimeStamp noteOffTimeStamp = [self.clock midiTimeStampForMusicTimeStamp:noteEvent.endTimeStamp];
		noteOff.midiTimestamp = noteOffTimeStamp;
		noteOff.channel = noteEvent.channel;
		noteOff.note = noteEvent.note;
		noteOff.velocity = noteEvent.releaseVelocity;
		NSMutableArray *pendingNoteOffsAtTimeStamp = pendingNoteOffs[@(noteOffTimeStamp)];
		if (!pendingNoteOffsAtTimeStamp) pendingNoteOffsAtTimeStamp	= [NSMutableArray array];
		NSNumber *timeStampNumber = @(noteOffTimeStamp);
		[pendingNoteOffsAtTimeStamp addObject:[MIKMIDICommandWithDestination commandWithDestination:destination command:noteOff]];
		pendingNoteOffs[@(noteOffTimeStamp)] = pendingNoteOffsAtTimeStamp;
		[pendingNoteOffTimeStamps addObject:timeStampNumber];
	}

	[self sendCommands:commands toDestinationEndpoint:destination];
}

- (void)sendPendingNoteOffCommandsUpToMIDITimeStamp:(MIDITimeStamp)toTimeStamp
{
	MIDITimeStamp allPendingNotesOffTimeStamp = 0;
	if (toTimeStamp == 0) {	// All notes off
		toTimeStamp = ULONG_LONG_MAX;
		allPendingNotesOffTimeStamp = MAX(self.lastProcessedMIDITimeStamp + 1, MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.001]);
	}

	NSMapTable *noteOffDestinationsToCommands = [NSMapTable strongToStrongObjectsMapTable];
	NSMutableDictionary *noteOffs = self.pendingNoteOffs;
	if (!noteOffs.count) return;
	NSMutableOrderedSet *noteOffTimeStamps = self.pendingNoteOffMIDITimeStamps;
	for (NSNumber *midiTimeStampNumber in [noteOffTimeStamps copy]) {
		MIDITimeStamp timeStamp = [midiTimeStampNumber unsignedLongLongValue];
		if (timeStamp > toTimeStamp) continue;

		NSArray *noteOffsAtTimeStamp = noteOffs[midiTimeStampNumber];
		for (MIKMIDICommandWithDestination *destinationCommand in noteOffsAtTimeStamp) {
			MIKMIDIDestinationEndpoint *destination = destinationCommand.destination;
			NSMutableArray *noteOffCommandsForDestination = [noteOffDestinationsToCommands objectForKey:destination] ? [noteOffDestinationsToCommands objectForKey:destination] : [NSMutableArray array];
			MIKMIDICommand *command = destinationCommand.command;
			if (allPendingNotesOffTimeStamp) {
				MIKMutableMIDICommand *mutableCommand = [command mutableCopy];
				mutableCommand.midiTimestamp = allPendingNotesOffTimeStamp;
				command = mutableCommand;
			}
			[noteOffCommandsForDestination addObject:command];
			[noteOffDestinationsToCommands setObject:noteOffCommandsForDestination forKey:destination];
		}
		[noteOffTimeStamps removeObject:midiTimeStampNumber];
		[noteOffs removeObjectForKey:midiTimeStampNumber];
	}

	for (MIKMIDIDestinationEndpoint *endpoint in [[noteOffDestinationsToCommands keyEnumerator] allObjects]) {
		[self sendCommands:[noteOffDestinationsToCommands objectForKey:endpoint] toDestinationEndpoint:endpoint];
	}
}

- (void)updateClockWithMusicTimeStamp:(MusicTimeStamp)musicTimeStamp tempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	MIKMIDIClock *clock = self.clock;
	NSMutableDictionary *historicalClocks = self.historicalClocks;
	if (!historicalClocks) {
		historicalClocks = [NSMutableDictionary dictionary];
		self.historicalClocks = historicalClocks;
		self.historicalClockMIDITimeStamps = [NSMutableOrderedSet orderedSet];
	} else {
		NSNumber *midiTimeStampNumber = @(midiTimeStamp);
		NSMutableOrderedSet *historicalClockMIDITimeStamps = self.historicalClockMIDITimeStamps;

		// Remove clocks old enough to not be needed anymore
		MIDITimeStamp oldTimeStamp = MIKMIDIGetCurrentTimeStamp() - [MIKMIDIClock midiTimeStampsPerTimeInterval:1];
		NSUInteger count = historicalClockMIDITimeStamps.count;
		NSMutableArray *timeStampsToRemove = [NSMutableArray array];
		NSMutableIndexSet *indexesToRemove = [NSMutableIndexSet indexSet];
		for (NSUInteger i = 0; i < count; i++) {
			NSNumber *timeStampNumber = historicalClockMIDITimeStamps[i];
			MIDITimeStamp timeStamp = timeStampNumber.unsignedLongValue;
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

		// Add clock to history
		historicalClocks[midiTimeStampNumber] = [clock copy];
		[historicalClockMIDITimeStamps addObject:midiTimeStampNumber];
	}

	[clock setMusicTimeStamp:musicTimeStamp withTempo:tempo atMIDITimeStamp:midiTimeStamp];
}

- (void)sendCommands:(NSArray *)commands toDestinationEndpoint:(MIKMIDIDestinationEndpoint *)endpoint
{
	NSError *error;
	if (commands.count && ![[MIKMIDIDeviceManager sharedDeviceManager] sendCommands:commands toEndpoint:endpoint error:&error]) {
		NSLog(@"%@: An error occurred scheduling the commands %@ for destination endpoint %@. %@", NSStringFromClass([self class]), commands, endpoint, error);
	}
}

#pragma mark - Recording

- (void)startRecording
{
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];
	[self startPlayback];
	self.recording = self.isPlaying;
}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp
{
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];
	[self startPlaybackAtTimeStamp:timeStamp];
	self.recording = self.isPlaying;
}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];
	[self startPlaybackAtTimeStamp:timeStamp MIDITimeStamp:midiTimeStamp];
	self.recording = self.isPlaying;
}

- (void)resumeRecording
{
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];
	[self resumePlayback];
	self.recording = self.isPlaying;
}

- (void)stopRecording
{
	[self stopPlayback];
	self.recording = self.isPlaying;
	self.pendingRecordedNoteEvents = nil;
}

- (void)recordMIDICommands:(NSSet *)commands
{
	NSMutableDictionary *commandsAtTimeStamps = [NSMutableDictionary dictionaryWithCapacity:commands.count];
	NSMutableOrderedSet *commandTimeStamps = [NSMutableOrderedSet orderedSetWithCapacity:commands.count];

	for (MIKMIDICommand *command in commands) {
		NSNumber *timeStampNumber = @(command.midiTimestamp);
		NSMutableArray *commandsAtTimeStamp = commandsAtTimeStamps[timeStampNumber];
		if (!commandsAtTimeStamp) commandsAtTimeStamp = [NSMutableArray arrayWithCapacity:1];
		[commandsAtTimeStamp addObject:command];
		commandsAtTimeStamps[timeStampNumber] = commandsAtTimeStamp;
		[commandTimeStamps addObject:timeStampNumber];
	}
	[commandTimeStamps sortUsingComparator:^NSComparisonResult(id obj1, id obj2) { return [obj1 compare:obj2]; }];

	NSMutableSet *events = [NSMutableSet setWithCapacity:commands.count];
	for (NSNumber *timeStampNumber in commandTimeStamps) {
		MIDITimeStamp midiTimeStamp = [timeStampNumber unsignedLongValue];
		MIKMIDIClock *clockAtTimeStamp;
		for (NSNumber *historicalClockTimeStamp in [[self.historicalClockMIDITimeStamps reverseObjectEnumerator] allObjects]) {
			if ([historicalClockTimeStamp unsignedLongValue] > midiTimeStamp) {
				clockAtTimeStamp = self.historicalClocks[historicalClockTimeStamp];
			} else {
				break;
			}
		}
		if (!clockAtTimeStamp) clockAtTimeStamp = self.clock;
		MusicTimeStamp musicTimeStamp = [clockAtTimeStamp musicTimeStampForMIDITimeStamp:midiTimeStamp];

		for (MIKMIDICommand *command in commandsAtTimeStamps[timeStampNumber]) {
			if ([command isKindOfClass:[MIKMIDINoteOnCommand class]]) {				// note On
				MIKMIDINoteOnCommand *noteOnCommand = (MIKMIDINoteOnCommand *)command;
				MIDINoteMessage message = { .channel = noteOnCommand.channel, .note = noteOnCommand.note, .velocity = noteOnCommand.velocity, 0, 0 };
				MIKMutableMIDINoteEvent *noteEvent = [MIKMutableMIDINoteEvent noteEventWithTimeStamp:musicTimeStamp message:message];
				self.pendingRecordedNoteEvents[@(noteOnCommand.note)] = noteEvent;
			} else if ([command isKindOfClass:[MIKMIDINoteOffCommand class]]) {		// note Off
				MIKMIDINoteOffCommand *noteOffCommand = (MIKMIDINoteOffCommand *)command;
				NSNumber *noteNumber = @(noteOffCommand.note);
				MIKMutableMIDINoteEvent *noteEvent = self.pendingRecordedNoteEvents[noteNumber];
				if (noteEvent) {
					noteEvent.releaseVelocity = noteOffCommand.velocity;
					noteEvent.duration = musicTimeStamp - noteEvent.timeStamp;
					[self.pendingRecordedNoteEvents removeObjectForKey:noteNumber];
					[events addObject:noteEvent];
				}
			}
		}
	}

	if (events.count) {
		for (MIKMIDITrack *track in self.recordEnabledTracks) {
			[track insertMIDIEvents:events];
		}
	}
}

#pragma mark - Timer

- (void)timerFired:(NSTimer *)timer
{
	[self processSequenceStartingFromMIDITimeStamp:self.lastProcessedMIDITimeStamp + 1];
}

#pragma mark - Properties

@synthesize currentTimeStamp = _currentTimeStamp;
- (MusicTimeStamp)currentTimeStamp
{
	if (self.isPlaying) {
		MusicTimeStamp timeStamp = [self.clock musicTimeStampForMIDITimeStamp:MIKMIDIGetCurrentTimeStamp()];
		_currentTimeStamp = (timeStamp <= self.sequence.length) ? timeStamp : self.sequence.length;
	}
	return _currentTimeStamp;
}

- (void)setCurrentTimeStamp:(MusicTimeStamp)currentTimeStamp
{
	_currentTimeStamp = currentTimeStamp;

	if (self.isPlaying) {
		if (self.isRecording) {
			[self stopRecording];
			[self startRecordingAtTimeStamp:_currentTimeStamp];
		} else {
			[self stopPlayback];
			[self startPlaybackAtTimeStamp:_currentTimeStamp];
		}
	}
}

@end



#pragma mark - 

@implementation MIKMIDIEventWithDestination

+ (instancetype)eventWithDestination:(MIKMIDIDestinationEndpoint *)destination event:(MIKMIDIEvent *)event
{
	MIKMIDIEventWithDestination *destinationEvent = [[self alloc] init];
	destinationEvent->_event = event;
	destinationEvent->_destination = destination;
	return destinationEvent;
}

@end


@implementation MIKMIDICommandWithDestination

+ (instancetype)commandWithDestination:(MIKMIDIDestinationEndpoint *)destination command:(MIKMIDICommand *)command
{
	MIKMIDICommandWithDestination *destinationCommand = [[self alloc] init];
	destinationCommand->_destination = destination;
	destinationCommand->_command = command;
	return destinationCommand;
}

@end
