//
//  MIKMIDIRecorder.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIRecorder.h"

@interface MIKMIDIRecorder ()
@property (nonatomic, getter=isRecording) BOOL recording;
@property (strong, nonatomic) NSMutableDictionary *pendingNotes;
@end


@implementation MIKMIDIRecorder

#pragma mark - Lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		self.pendingNotes = [NSMutableDictionary dictionary];
	}
	return self;
}

#pragma mark - Recording

- (void)prepareRecording
{
	[self preparePlayback];
}

- (void)startRecording
{
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.stopPlaybackAtEndOfSequence = NO;
	[self startPlayback];
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
	self.recording = self.isPlaying;
}

- (void)startRecordingFromPosition:(MusicTimeStamp)position
{
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.stopPlaybackAtEndOfSequence = NO;
	[self startPlaybackFromPosition:position];
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
	self.recording = self.isPlaying;
}

- (void)resumeRecording
{
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.stopPlaybackAtEndOfSequence = NO;
	[self resumePlayback];
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
	self.recording = self.isPlaying;
}

- (void)stopRecording
{
	[self stopPlayback];
	self.recording = self.isPlaying;
}

#pragma mark - MIDI Messages

- (void)recordMIDICommands:(NSSet *)commands
{
	if (!self.isRecording) return;

	NSMutableSet *events = [NSMutableSet setWithCapacity:commands.count];
	MIKMIDISequence *sequence = self.sequence;
	for (MIKMIDICommand *command in commands) {
		if ([command isKindOfClass:[MIKMIDINoteOnCommand class]]) {				// note On
			MIKMIDINoteOnCommand *noteOnCommand = (MIKMIDINoteOnCommand *)command;
			MIDINoteMessage message = { .channel = noteOnCommand.channel, .note = noteOnCommand.note, .velocity = noteOnCommand.velocity, 0, 0 };
			MIKMutableMIDINoteEvent *noteEvent = [MIKMutableMIDINoteEvent noteEventWithTimeStamp:[sequence equivalentTimeStampForLoopedTimeStamp:self.currentTimeStamp] message:message];
			self.pendingNotes[@(noteOnCommand.note)] = noteEvent;
		} else if ([command isKindOfClass:[MIKMIDINoteOffCommand class]]) {		// note Off
			MIKMIDINoteOffCommand *noteOffCommand = (MIKMIDINoteOffCommand *)command;
			NSNumber *noteNumber = @(noteOffCommand.note);
			MIKMutableMIDINoteEvent *noteEvent = self.pendingNotes[noteNumber];
			noteEvent.releaseVelocity = noteOffCommand.velocity;
			noteEvent.duration = [sequence equivalentTimeStampForLoopedTimeStamp:self.currentTimeStamp] - noteEvent.timeStamp;
			[self.pendingNotes removeObjectForKey:noteNumber];
			[events addObject:noteEvent];
		}
	}

	for (MIKMIDITrack *track in self.recordEnabledTracks) {
		[track insertMIDIEvents:events];
	}
}

@end
