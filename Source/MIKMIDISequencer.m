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

@property (nonatomic) MIDITimeStamp lastProcessedMIDITimeStamp;
@property (strong, nonatomic) NSTimer *timer;

@property (strong, nonatomic) NSMutableDictionary *pendingNoteOffs;
@property (strong, nonatomic) NSMutableOrderedSet *pendingNoteOffMIDITimeStamps;

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
	MIDITimeStamp midiTimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.005];
	[self startPlaybackAtTimeStamp:timeStamp MIDITimeStamp:midiTimeStamp];
}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	Float64 startingTempo;
	if (![self.sequence getTempo:&startingTempo atTimeStamp:timeStamp]) startingTempo = MIKMIDISequencerDefaultTempo;
	[self.clock setMusicTimeStamp:timeStamp withTempo:startingTempo atMIDITimeStamp:midiTimeStamp];

	self.playing = YES;
	self.pendingNoteOffs = [NSMutableDictionary dictionary];
	self.pendingNoteOffMIDITimeStamps = [NSMutableOrderedSet orderedSet];
	self.lastProcessedMIDITimeStamp = midiTimeStamp - 1;
	self.timer = [NSTimer timerWithTimeInterval:0.001 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
	[[NSRunLoop mainRunLoop] addTimer:self.timer forMode:NSRunLoopCommonModes];
	[self.timer fire];
}

- (void)resumePlayback
{
	MusicTimeStamp lastMusicTimeStamp = [self.clock musicTimeStampForMIDITimeStamp:self.lastProcessedMIDITimeStamp - 1];
	[self startPlaybackAtTimeStamp:lastMusicTimeStamp];
}

- (void)stopPlayback
{
	[self.timer invalidate];
	self.timer = nil;
	[self sendPendingNoteOffCommandsUpToMIDITimeStamp:0];
	self.pendingNoteOffs = nil;
	self.pendingNoteOffMIDITimeStamps = nil;
	self.playing = NO;
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
	if (toTimeStamp == 0) {
		toTimeStamp = ULONG_LONG_MAX;
		allPendingNotesOffTimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.01];
	}

	NSMapTable *noteOffDestinationsToCommands = [NSMapTable strongToStrongObjectsMapTable];
	NSMutableDictionary *noteOffs = self.pendingNoteOffs;
	if (!noteOffs.count) return;
	NSMutableOrderedSet *noteOffTimeStamps = self.pendingNoteOffMIDITimeStamps;
	for (NSNumber *midiTimeStampNumber in [noteOffTimeStamps copy]) {
		MIDITimeStamp timeStamp = [midiTimeStampNumber unsignedLongLongValue];
		if (timeStamp > toTimeStamp) break;

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

}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp
{

}

- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{

}

- (void)resumeRecording
{

}

- (void)stopRecording
{

}

- (void)recordMIDICommands:(NSSet *)commands
{

}

#pragma mark - Timer

- (void)timerFired:(NSTimer *)timer
{
	[self processSequenceStartingFromMIDITimeStamp:self.lastProcessedMIDITimeStamp + 1];
}

- (void)processSequenceStartingFromMIDITimeStamp:(MIDITimeStamp)fromMIDITimeStamp
{
	MIDITimeStamp toMIDITimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.01];
	if (toMIDITimeStamp < fromMIDITimeStamp) return;
	MIKMIDIClock *clock = self.clock;

	MIKMIDISequence *sequence = self.sequence;
	BOOL isLooping = self.isLooping;
	MusicTimeStamp maxMusicTimeStamp;
	if (isLooping) {
		maxMusicTimeStamp = self.loopEndTimeStamp;
	} else {
		maxMusicTimeStamp = self.isRecording ? DBL_MAX : sequence.length;
	}

	MusicTimeStamp fromMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:fromMIDITimeStamp];
	MusicTimeStamp calculatedToMusicTimeStamp = [clock musicTimeStampForMIDITimeStamp:toMIDITimeStamp];
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
		MIDITimeStamp midiTimeStamp = [clock midiTimeStampForMusicTimeStamp:musicTimeStamp];
		MIKMIDITempoEvent *tempoEventAtTimeStamp = tempoEvents[timeStampKey];
		if (tempoEventAtTimeStamp) [clock setMusicTimeStamp:musicTimeStamp withTempo:tempoEventAtTimeStamp.bpm atMIDITimeStamp:midiTimeStamp];

		NSArray *events = timeStampEvents[timeStampKey];
		for (id eventObject in events) {
			if ([eventObject isKindOfClass:[MIKMIDIEventWithDestination class]]) {
				[self scheduleEventWithDestination:eventObject atMIDITimeStamp:midiTimeStamp];
			}
		}

		lastProcessedMIDITimeStamp = midiTimeStamp;
	}

	self.lastProcessedMIDITimeStamp = lastProcessedMIDITimeStamp;

	// Handle looping
	if (isLooping && calculatedToMusicTimeStamp > toMusicTimeStamp) {
		MusicTimeStamp loopStartMusicTimeStamp = self.loopStartTimeStamp;
		Float64 tempo;
		if (![sequence getTempo:&tempo atTimeStamp:loopStartMusicTimeStamp]) tempo = MIKMIDISequencerDefaultTempo;
		MusicTimeStamp loopLength = self.loopEndTimeStamp - loopStartMusicTimeStamp;

		MIDITimeStamp loopStartMIDITimeStamp = [clock midiTimeStampForMusicTimeStamp:loopStartMusicTimeStamp + loopLength];
		[clock setMusicTimeStamp:loopStartMusicTimeStamp withTempo:tempo atMIDITimeStamp:loopStartMIDITimeStamp];
		[self processSequenceStartingFromMIDITimeStamp:loopStartMIDITimeStamp];
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
