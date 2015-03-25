//
//  MIKMIDISequencer.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequencer.h"
#import <mach/mach_time.h>
#import "MIKMIDISequence.h"
#import "MIKMIDITrack.h"
#import "MIKMIDIClock.h"
#import "MIKMIDITempoEvent.h"
#import "MIKMIDINoteEvent.h"
#import "MIKMIDIChannelEvent.h"
#import "MIKMIDINoteOnCommand.h"
#import "MIKMIDINoteOffCommand.h"
#import "MIKMIDIDeviceManager.h"
#import "MIKMIDIMetronome.h"
#import "MIKMIDIMetaTimeSignatureEvent.h"
#import "MIKMIDIClientDestinationEndpoint.h"
#import "MIKMIDIUtilities.h"
#import "MIKMIDISynthesizer.h"

#if !__has_feature(objc_arc)
#error MIKMIDISequencer.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

#define MIKMIDISequencerDefaultTempo			120


#pragma mark -

@interface MIKMIDIEventWithDestination : NSObject
@property (nonatomic, strong) MIKMIDIEvent *event;
@property (nonatomic, strong) MIKMIDIDestinationEndpoint *destination;
+ (instancetype)eventWithDestination:(MIKMIDIDestinationEndpoint *)destination event:(MIKMIDIEvent *)event;
@end


@interface MIKMIDICommandWithDestination : NSObject
@property (nonatomic, strong) MIKMIDICommand *command;
@property (nonatomic, strong) MIKMIDIDestinationEndpoint *destination;
+ (instancetype)commandWithDestination:(MIKMIDIDestinationEndpoint *)destination command:(MIKMIDICommand *)command;
@end



#pragma mark -

@interface MIKMIDISequencer ()

@property (readonly, nonatomic) MIKMIDIClock *clock;

@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isRecording) BOOL recording;
@property (nonatomic, getter=isLooping) BOOL looping;

@property (readonly, nonatomic) MusicTimeStamp actualLoopEndTimeStamp;

@property (nonatomic) MIDITimeStamp lastProcessedMIDITimeStamp;
@property (nonatomic, strong) NSTimer *processingTimer;

@property (nonatomic, strong) NSMutableDictionary *pendingNoteOffs;
@property (nonatomic, strong) NSMutableOrderedSet *pendingNoteOffMIDITimeStamps;

@property (nonatomic, strong) NSMutableDictionary *historicalClocks;
@property (nonatomic, strong) NSMutableOrderedSet *historicalClockMIDITimeStamps;

@property (nonatomic, strong) NSMutableDictionary *pendingRecordedNoteEvents;

@property (nonatomic) MusicTimeStamp playbackOffset;
@property (nonatomic) MusicTimeStamp startingTimeStamp;

@property (nonatomic, strong) NSMapTable *tracksToDestinationsMap;
@property (nonatomic, strong) NSMapTable *tracksToDefaultSynthsMap;
@property (nonatomic, strong) MIKMIDIClientDestinationEndpoint *metronomeEndpoint;

@end


@implementation MIKMIDISequencer

#pragma mark - Lifecycle

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence
{
	if (self = [super init]) {
		_sequence = sequence;
		_clock = [MIKMIDIClock clock];
		_loopEndTimeStamp = -1;
		_preRoll = 4;
		_clickTrackStatus = MIKMIDISequencerClickTrackStatusEnabledInRecord;
		_tracksToDestinationsMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
		_tracksToDefaultSynthsMap = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory];
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
	if (self.isPlaying) [self stop];

	MusicTimeStamp startingTimeStamp = timeStamp + self.playbackOffset;
	self.startingTimeStamp = startingTimeStamp;

	Float64 startingTempo = [self.sequence tempoAtTimeStamp:startingTimeStamp];
	if (!startingTempo) startingTempo = MIKMIDISequencerDefaultTempo;
	[self updateClockWithMusicTimeStamp:timeStamp tempo:startingTempo atMIDITimeStamp:midiTimeStamp];

	self.playing = YES;
	self.pendingNoteOffs = [NSMutableDictionary dictionary];
	self.pendingNoteOffMIDITimeStamps = [NSMutableOrderedSet orderedSet];
	self.lastProcessedMIDITimeStamp = midiTimeStamp - 1;
	self.processingTimer = [NSTimer timerWithTimeInterval:0.05
													   target:self
													 selector:@selector(processingTimerFired:)
													 userInfo:nil
													  repeats:YES];
	[self.processingTimer fire];
}

- (void)resumePlayback
{
	[self startPlaybackAtTimeStamp:self.currentTimeStamp];
}

- (void)stop
{
	MIDITimeStamp stopTimeStamp = MIKMIDIGetCurrentTimeStamp();
	if (!self.isPlaying) return;

	self.processingTimer = nil;
	[self sendPendingNoteOffCommandsUpToMIDITimeStamp:0];
	self.pendingNoteOffs = nil;
	self.pendingNoteOffMIDITimeStamps = nil;
	[self recordAllPendingNoteEventsWithOffTimeStamp:[self.clock musicTimeStampForMIDITimeStamp:stopTimeStamp]];
	self.historicalClocks = nil;
	self.historicalClockMIDITimeStamps = nil;
	self.pendingRecordedNoteEvents = nil;
	self.looping = NO;
	_currentTimeStamp = (stopTimeStamp <= self.sequence.length + self.playbackOffset) ? stopTimeStamp : self.sequence.length;
	self.playbackOffset = 0;
	self.playing = NO;
	self.recording = NO;
}

- (void)processSequenceStartingFromMIDITimeStamp:(MIDITimeStamp)fromMIDITimeStamp
{
	MIDITimeStamp toMIDITimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.1];
	if (toMIDITimeStamp < fromMIDITimeStamp) return;
	MIKMIDIClock *clock = self.clock;

	MIKMIDISequence *sequence = self.sequence;
	MusicTimeStamp playbackOffset = self.playbackOffset;
	MusicTimeStamp loopStartTimeStamp = self.loopStartTimeStamp + playbackOffset;
	MusicTimeStamp loopEndTimeStamp = self.actualLoopEndTimeStamp + playbackOffset;
	MusicTimeStamp fromMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:fromMIDITimeStamp];
	MusicTimeStamp calculatedToMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:toMIDITimeStamp];
	BOOL isLooping = (self.shouldLoop && !self.isLooping && calculatedToMusicTimeStamp > loopStartTimeStamp && loopEndTimeStamp > loopStartTimeStamp);
	self.looping = isLooping;
	MusicTimeStamp toMusicTimeStamp = MIN(calculatedToMusicTimeStamp, isLooping ? loopEndTimeStamp : sequence.length);

	// Send pending note off commands
	MIDITimeStamp actualToMIDITimeStamp = [clock midiTimeStampForMusicTimeStamp:toMusicTimeStamp];
	[self sendPendingNoteOffCommandsUpToMIDITimeStamp:actualToMIDITimeStamp];

	// Get relevant tempo events
	NSMutableDictionary *tempoEventsByTimeStamp = [NSMutableDictionary dictionary];
	NSMutableDictionary *otherEventsByTimeStamp = [NSMutableDictionary dictionary];
	for (MIKMIDITempoEvent *tempoEvent in [sequence.tempoTrack eventsOfClass:[MIKMIDITempoEvent class] fromTimeStamp:MAX(fromMusicTimeStamp - playbackOffset, 0) toTimeStamp:toMusicTimeStamp - playbackOffset]) {
		NSNumber *timeStampKey = @(tempoEvent.timeStamp + playbackOffset);
		otherEventsByTimeStamp[timeStampKey] = [NSMutableArray arrayWithObject:tempoEvent];
		tempoEventsByTimeStamp[timeStampKey] = tempoEvent;
	}

	// Get other events
	for (MIKMIDITrack *track in sequence.tracks) {
		MIKMIDIDestinationEndpoint *destination = [self destinationEndpointForTrack:track];
		for (MIKMIDIEvent *event in [track eventsFromTimeStamp:MAX(fromMusicTimeStamp - playbackOffset, 0) toTimeStamp:toMusicTimeStamp - playbackOffset]) {
			NSNumber *timeStampKey = @(event.timeStamp + playbackOffset);
			NSMutableArray *eventsAtTimeStamp = otherEventsByTimeStamp[timeStampKey] ? otherEventsByTimeStamp[timeStampKey] : [NSMutableArray array];
			[eventsAtTimeStamp addObject:[MIKMIDIEventWithDestination eventWithDestination:destination event:event]];
			otherEventsByTimeStamp[timeStampKey] = eventsAtTimeStamp;
		}
	}

	// Get click track events
	for (MIKMIDIEventWithDestination *destinationEvent in [self clickTrackEventsFromTimeStamp:fromMusicTimeStamp toTimeStamp:toMusicTimeStamp]) {
		NSNumber *timeStampKey = @(destinationEvent.event.timeStamp + playbackOffset);
		NSMutableArray *eventsAtTimesStamp = otherEventsByTimeStamp[timeStampKey] ? otherEventsByTimeStamp[timeStampKey] : [NSMutableArray array];
		[eventsAtTimesStamp addObject:destinationEvent];
		otherEventsByTimeStamp[timeStampKey] = eventsAtTimesStamp;
	}

	// Schedule events
	MIDITimeStamp lastProcessedMIDITimeStamp = fromMIDITimeStamp;
	for (NSNumber *timeStampKey in [otherEventsByTimeStamp.allKeys sortedArrayUsingSelector:@selector(compare:)]) {
		MusicTimeStamp musicTimeStamp = timeStampKey.doubleValue;
		if (isLooping && (musicTimeStamp < loopStartTimeStamp || musicTimeStamp >= loopEndTimeStamp)) continue;
		MIDITimeStamp midiTimeStamp = [clock midiTimeStampForMusicTimeStamp:musicTimeStamp];
		if (midiTimeStamp < MIKMIDIGetCurrentTimeStamp() && midiTimeStamp > fromMIDITimeStamp) continue;	// prevents events that were just recorded from being scheduled
		
		MIKMIDITempoEvent *tempoEventAtTimeStamp = tempoEventsByTimeStamp[timeStampKey];
		if (tempoEventAtTimeStamp) [self updateClockWithMusicTimeStamp:musicTimeStamp tempo:tempoEventAtTimeStamp.bpm atMIDITimeStamp:midiTimeStamp];

		NSArray *events = otherEventsByTimeStamp[timeStampKey];
		for (id eventObject in events) {
			if ([eventObject isKindOfClass:[MIKMIDIEventWithDestination class]]) {
				[self scheduleEventWithDestination:eventObject];
			}
		}

		lastProcessedMIDITimeStamp = midiTimeStamp;
	}

	self.lastProcessedMIDITimeStamp = lastProcessedMIDITimeStamp;

	// Handle looping or stopping at the end of the sequence
	if (isLooping) {
		if (calculatedToMusicTimeStamp > toMusicTimeStamp) {
			[self recordAllPendingNoteEventsWithOffTimeStamp:loopEndTimeStamp];
			Float64 tempo = [sequence tempoAtTimeStamp:loopStartTimeStamp];
			if (!tempo) tempo = MIKMIDISequencerDefaultTempo;
			MusicTimeStamp loopLength = loopEndTimeStamp - loopStartTimeStamp;

			MIDITimeStamp loopStartMIDITimeStamp = [clock midiTimeStampForMusicTimeStamp:loopStartTimeStamp + loopLength];
			[self updateClockWithMusicTimeStamp:loopStartTimeStamp tempo:tempo atMIDITimeStamp:loopStartMIDITimeStamp];
			[self processSequenceStartingFromMIDITimeStamp:loopStartMIDITimeStamp];
		}
	} else if (!self.isRecording) { // Don't stop automatically during recording
		MIDITimeStamp systemTimeStamp = MIKMIDIGetCurrentTimeStamp();
		if ((systemTimeStamp > lastProcessedMIDITimeStamp) && ([clock musicTimeStampForMIDITimeStamp:systemTimeStamp] >= sequence.length + playbackOffset)) {
			[self stop];
		}
	}
}

- (void)scheduleEventWithDestination:(MIKMIDIEventWithDestination *)destinationEvent
{
	MIKMIDIEvent *event = destinationEvent.event;
	MIKMIDIDestinationEndpoint *destination = destinationEvent.destination;
	NSMutableDictionary *pendingNoteOffs = self.pendingNoteOffs;
	NSMutableOrderedSet *pendingNoteOffTimeStamps = self.pendingNoteOffMIDITimeStamps;

	NSArray *commands = nil;
	if (event.eventType == MIKMIDIEventTypeMIDINoteMessage) {
		commands = [MIKMIDICommand commandsFromNoteEvent:(MIKMIDINoteEvent *)event clock:self.clock];
		
		// Add note off to pending note offs
		MIKMIDINoteOffCommand *noteOff = [commands lastObject];
		MIDITimeStamp noteOffTimeStamp = noteOff.midiTimestamp + [self.clock midiTimeStampForMusicTimeStamp:self.playbackOffset];
		NSMutableArray *pendingNoteOffsAtTimeStamp = pendingNoteOffs[@(noteOffTimeStamp)];
		if (!pendingNoteOffsAtTimeStamp) pendingNoteOffsAtTimeStamp	= [NSMutableArray array];
		NSNumber *timeStampNumber = @(noteOffTimeStamp);
		[pendingNoteOffsAtTimeStamp addObject:[MIKMIDICommandWithDestination commandWithDestination:destination command:noteOff]];
		pendingNoteOffs[@(noteOffTimeStamp)] = pendingNoteOffsAtTimeStamp;
		[pendingNoteOffTimeStamps addObject:timeStampNumber];
	} else if ([event isKindOfClass:[MIKMIDIChannelEvent class]]) {
		MIKMIDICommand *command = [MIKMIDICommand commandFromChannelEvent:(MIKMIDIChannelEvent *)event clock:self.clock];
		commands = [NSArray arrayWithObjects:command, nil];
	}
	
	// Adjust commands' time stamps to account for our playback offset.
	NSMutableArray *adjustedCommands = [NSMutableArray array];
	for (MIKMIDICommand *command in commands) {
		MIKMutableMIDICommand *scratch = [command mutableCopy];
		MusicTimeStamp musicTimestamp = [self.clock musicTimeStampForMIDITimeStamp:scratch.midiTimestamp];
		scratch.midiTimestamp = [self.clock midiTimeStampForMusicTimeStamp:(musicTimestamp + self.playbackOffset)];
		[adjustedCommands addObject:scratch];
	}

	if ([adjustedCommands count]) [self sendCommands:adjustedCommands toDestinationEndpoint:destination];
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
	[self prepareForRecordingWithPreRoll:YES];
	[self startPlayback];
}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp
{
	[self prepareForRecordingWithPreRoll:YES];
	[self startPlaybackAtTimeStamp:timeStamp];
}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	[self prepareForRecordingWithPreRoll:YES];
	[self startPlaybackAtTimeStamp:timeStamp MIDITimeStamp:midiTimeStamp];
}

- (void)resumeRecording
{
	[self prepareForRecordingWithPreRoll:YES];
	[self resumePlayback];
}

- (void)prepareForRecordingWithPreRoll:(BOOL)includePreRoll
{
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];
	if (includePreRoll) self.playbackOffset = self.preRoll;
	self.recording = YES;
}

- (void)recordMIDICommand:(MIKMIDICommand *)command
{
	if (!self.isRecording) return;
	
	MIDITimeStamp midiTimeStamp = command.midiTimestamp;
	MIKMIDIClock *clockAtTimeStamp;
	for (NSNumber *historicalClockTimeStamp in [[self.historicalClockMIDITimeStamps reverseObjectEnumerator] allObjects]) {
		if ([historicalClockTimeStamp unsignedLongLongValue] > midiTimeStamp) {
			clockAtTimeStamp = self.historicalClocks[historicalClockTimeStamp];
		} else {
			break;
		}
	}
	if (!clockAtTimeStamp) clockAtTimeStamp = self.clock;

	MusicTimeStamp playbackOffset = self.playbackOffset;
	MusicTimeStamp musicTimeStamp = [clockAtTimeStamp musicTimeStampForMIDITimeStamp:midiTimeStamp] - playbackOffset;

	MIKMIDIEvent *event;
	if ([command isKindOfClass:[MIKMIDINoteOnCommand class]]) {				// note On
		MIKMIDINoteOnCommand *noteOnCommand = (MIKMIDINoteOnCommand *)command;
		if (noteOnCommand.velocity) {
			MIDINoteMessage message = { .channel = noteOnCommand.channel, .note = noteOnCommand.note, .velocity = noteOnCommand.velocity, 0, 0 };
			MIKMutableMIDINoteEvent *noteEvent = [MIKMutableMIDINoteEvent noteEventWithTimeStamp:musicTimeStamp message:message];
			NSNumber *noteNumber = @(noteOnCommand.note);
			NSMutableSet *noteEventsAtNote = self.pendingRecordedNoteEvents[noteNumber];
			if (!noteEventsAtNote) {
				noteEventsAtNote = [NSMutableSet setWithCapacity:1];
				self.pendingRecordedNoteEvents[noteNumber] = noteEventsAtNote;
			}
			[noteEventsAtNote addObject:noteEvent];
		} else {	// Velocity is 0, treat as a note Off per MIDI spec
			event = [self pendingNoteEventWithNoteNumber:@(noteOnCommand.note) channel:noteOnCommand.channel releaseVelocity:0 offTimeStamp:musicTimeStamp];
		}
	} else if ([command isKindOfClass:[MIKMIDINoteOffCommand class]]) {		// note Off
		MIKMIDINoteOffCommand *noteOffCommand = (MIKMIDINoteOffCommand *)command;
		event = [self pendingNoteEventWithNoteNumber:@(noteOffCommand.note) channel:noteOffCommand.channel releaseVelocity:noteOffCommand.velocity offTimeStamp:musicTimeStamp];
	}

	if (event) [self.recordEnabledTracks makeObjectsPerformSelector:@selector(addEvent:) withObject:event];
}

- (void)recordAllPendingNoteEventsWithOffTimeStamp:(MusicTimeStamp)offTimeStamp
{
	NSMutableSet *events = [NSMutableSet set];

	NSMutableDictionary *pendingRecordedNoteEvents = self.pendingRecordedNoteEvents;
	for (NSNumber *noteNumber in pendingRecordedNoteEvents) {
		for (MIKMutableMIDINoteEvent *event in pendingRecordedNoteEvents[noteNumber]) {
			event.releaseVelocity = 0;
			event.duration = offTimeStamp - event.timeStamp;
			[events addObject:event];
		}
	}
	self.pendingRecordedNoteEvents = [NSMutableDictionary dictionary];

	if ([events count]) [self.recordEnabledTracks makeObjectsPerformSelector:@selector(addEvents:) withObject:events];
}

- (MIKMIDINoteEvent	*)pendingNoteEventWithNoteNumber:(NSNumber *)noteNumber channel:(UInt8)channel releaseVelocity:(UInt8)releaseVelocity offTimeStamp:(MusicTimeStamp)offTimeStamp
{
	NSMutableSet *pendingRecordedNoteEventsAtNote = self.pendingRecordedNoteEvents[noteNumber];
	for (MIKMutableMIDINoteEvent *noteEvent in [pendingRecordedNoteEventsAtNote copy]) {
		if (channel == noteEvent.channel) {
			noteEvent.releaseVelocity = releaseVelocity;
			noteEvent.duration = offTimeStamp - noteEvent.timeStamp;

			if (pendingRecordedNoteEventsAtNote.count > 1) {
				[pendingRecordedNoteEventsAtNote removeObject:noteEvent];
			} else {
				[self.pendingRecordedNoteEvents removeObjectForKey:noteNumber];
			}

			return noteEvent;
		}
	}
	return nil;
}

#pragma mark - Configuration

- (void)setDestinationEndpoint:(MIKMIDIDestinationEndpoint *)endpoint forTrack:(MIKMIDITrack *)track
{
	[self.tracksToDestinationsMap setObject:endpoint forKey:track];
	[self.tracksToDefaultSynthsMap removeObjectForKey:track];
}

- (MIKMIDIDestinationEndpoint *)destinationEndpointForTrack:(MIKMIDITrack *)track
{
	MIKMIDIDestinationEndpoint *result = [self.tracksToDestinationsMap objectForKey:track];
	if (!result) {
		// Create a default endpoint and synthesizer
		NSString *name = [NSString stringWithFormat:@"<%@: %p> Default Endpoint %d", NSStringFromClass([self class]), self, (int)track.trackNumber];
		result = [[MIKMIDIClientDestinationEndpoint alloc] initWithName:name receivedMessagesHandler:nil];
		[self setDestinationEndpoint:result forTrack:track];
		
		MIKMIDISynthesizer *synth = [MIKMIDIEndpointSynthesizer synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)result];
		[self.tracksToDefaultSynthsMap setObject:synth forKey:track];
	}
	return result;
}

- (MIKMIDISynthesizer *)builtinSynthesizerForTrack:(MIKMIDITrack *)track
{
	[[self destinationEndpointForTrack:track] self]; // Will force creation of a synth if one doesn't exist, but should
	return [self.tracksToDefaultSynthsMap objectForKey:track];
}

#pragma mark - Click Track

- (NSMutableArray *)clickTrackEventsFromTimeStamp:(MusicTimeStamp)fromTimeStamp toTimeStamp:(MusicTimeStamp)toTimeStamp
{
	MIKMIDISequencerClickTrackStatus clickTrackStatus = self.clickTrackStatus;
	if (clickTrackStatus == MIKMIDISequencerClickTrackStatusDisabled) return nil;
	if (!self.isRecording && clickTrackStatus != MIKMIDISequencerClickTrackStatusAlwaysEnabled) return nil;

	NSMutableArray *clickEvents = [NSMutableArray array];
	MIDINoteMessage tickMessage = self.metronome.tickMessage;
	MIDINoteMessage tockMessage = self.metronome.tockMessage;
	MIKMIDIDestinationEndpoint *destination = self.metronomeEndpoint;

	MIKMIDISequence *sequence = self.sequence;
	MusicTimeStamp playbackOffset = self.playbackOffset;
	MIKMIDITimeSignature timeSignature = [sequence timeSignatureAtTimeStamp:fromTimeStamp - playbackOffset];
	NSMutableArray *timeSignatureEvents = [[sequence.tempoTrack eventsOfClass:[MIKMIDIMetaTimeSignatureEvent class]
																fromTimeStamp:MAX(fromTimeStamp - playbackOffset, 0)
																  toTimeStamp:toTimeStamp] mutableCopy];

	MusicTimeStamp clickTimeStamp = floor(fromTimeStamp);
	while (clickTimeStamp <= toTimeStamp) {
		if (clickTrackStatus == MIKMIDISequencerClickTrackStatusEnabledOnlyInPreRoll && clickTimeStamp >= self.startingTimeStamp) break;

		MIKMIDIMetaTimeSignatureEvent *event = [timeSignatureEvents firstObject];
		if (event && event.timeStamp - playbackOffset <= clickTimeStamp) {
			timeSignature = (MIKMIDITimeSignature) { .numerator = event.numerator, .denominator = event.denominator };
			[timeSignatureEvents removeObjectAtIndex:0];
		}

		if (clickTimeStamp >= fromTimeStamp) {	// ignore if clickTimeStamp is still less than fromTimeStamp (from being floored)
			NSInteger adjustedTimeStamp = clickTimeStamp * timeSignature.denominator / 4.0;
			BOOL isTick = !((adjustedTimeStamp + timeSignature.numerator) % (timeSignature.numerator));
			MIDINoteMessage clickMessage = isTick ? tickMessage : tockMessage;
			MIKMIDINoteEvent *noteEvent = [MIKMIDINoteEvent noteEventWithTimeStamp:clickTimeStamp - playbackOffset message:clickMessage];
			[clickEvents addObject:[MIKMIDIEventWithDestination eventWithDestination:destination event:noteEvent]];
		}

		clickTimeStamp += 4.0 / timeSignature.denominator;
	}

	return clickEvents;
}

#pragma mark - Timer

- (void)processingTimerFired:(NSTimer *)timer
{
	[self processSequenceStartingFromMIDITimeStamp:self.lastProcessedMIDITimeStamp + 1];
}

#pragma mark - Properties

@synthesize currentTimeStamp = _currentTimeStamp;
- (MusicTimeStamp)currentTimeStamp
{
	if (self.isPlaying) {
		MusicTimeStamp timeStamp = [self.clock musicTimeStampForMIDITimeStamp:MIKMIDIGetCurrentTimeStamp()];
		MusicTimeStamp playbackOffset = self.playbackOffset;
		_currentTimeStamp = (timeStamp <= self.sequence.length + playbackOffset) ? timeStamp - playbackOffset : self.sequence.length;
	}
	return _currentTimeStamp;
}

- (void)setCurrentTimeStamp:(MusicTimeStamp)currentTimeStamp
{
	_currentTimeStamp = currentTimeStamp;

	if (self.isPlaying) {
		BOOL isRecording = self.isRecording;
		[self stop];
		if (isRecording) [self prepareForRecordingWithPreRoll:NO];
		[self startPlaybackAtTimeStamp:_currentTimeStamp];
	}
}

- (MusicTimeStamp)actualLoopEndTimeStamp
{
	return (_loopEndTimeStamp < 0) ? self.sequence.length : _loopEndTimeStamp;
}

- (void)setPreRoll:(MusicTimeStamp)preRoll
{
	_preRoll = (preRoll >= 0) ? preRoll : 0;
}

- (void)setProcessingTimer:(NSTimer *)processingTimer
{
	if (processingTimer != _processingTimer) {
		[_processingTimer invalidate];
		_processingTimer = processingTimer;
		if (_processingTimer) [[NSRunLoop currentRunLoop] addTimer:_processingTimer forMode:NSRunLoopCommonModes];
	}
}

- (MIKMIDIClientDestinationEndpoint *)metronomeEndpoint
{
	if (!_metronomeEndpoint) _metronomeEndpoint = [[MIKMIDIClientDestinationEndpoint alloc] initWithName:@"MIKMIDIClickTrackEndpoint" receivedMessagesHandler:NULL];
	return _metronomeEndpoint;
}

@synthesize metronome = _metronome;
- (MIKMIDIMetronome *)metronome
{
	if (!_metronome) _metronome = [[MIKMIDIMetronome alloc] initWithClientDestinationEndpoint:self.metronomeEndpoint];
	return _metronome;
}

- (void)setMetronome:(MIKMIDIMetronome *)metronome
{
	if (_metronome != metronome) {
		_metronome = metronome;
		_metronomeEndpoint = (MIKMIDIClientDestinationEndpoint *)metronome.endpoint;
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
