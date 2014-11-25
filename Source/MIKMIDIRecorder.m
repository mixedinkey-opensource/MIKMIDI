//
//  MIKMIDIRecorder.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIRecorder.h"
#import "MIKMIDI.h"

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
		self.clickTrackEnabledInRecord = YES;
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
	BOOL playerClickTrackEnabled = self.isClickTrackEnabled;
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.clickTrackEnabled = self.isClickTrackEnabledInRecord;
	self.stopPlaybackAtEndOfSequence = NO;

	[self startPlayback];
	self.recording = self.isPlaying;

	self.clickTrackEnabled = playerClickTrackEnabled;
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
}

- (void)startRecordingFromPosition:(MusicTimeStamp)position
{
	BOOL playerClickTrackEnabled = self.isClickTrackEnabled;
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.clickTrackEnabled = self.isClickTrackEnabledInRecord;
	self.stopPlaybackAtEndOfSequence = NO;

	[self startPlaybackFromPosition:position];
	self.recording = self.isPlaying;

	self.clickTrackEnabled = playerClickTrackEnabled;
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
}

- (void)resumeRecording
{
	BOOL playerClickTrackEnabled = self.isClickTrackEnabled;
	BOOL playerStopsAtEndOfSequence = self.stopPlaybackAtEndOfSequence;
	self.clickTrackEnabled = self.isClickTrackEnabledInRecord;
	self.stopPlaybackAtEndOfSequence = NO;

	[self resumePlayback];
	self.recording = self.isPlaying;

	self.clickTrackEnabled = playerClickTrackEnabled;
	self.stopPlaybackAtEndOfSequence = playerStopsAtEndOfSequence;
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
			MusicTimeStamp startTimeStamp = self.isLooping ? [sequence equivalentTimeStampForLoopedTimeStamp:self.currentTimeStamp] : self.currentTimeStamp;
			MIKMutableMIDINoteEvent *noteEvent = [MIKMutableMIDINoteEvent noteEventWithTimeStamp:startTimeStamp message:message];
			self.pendingNotes[@(noteOnCommand.note)] = noteEvent;
		} else if ([command isKindOfClass:[MIKMIDINoteOffCommand class]]) {		// note Off
			MIKMIDINoteOffCommand *noteOffCommand = (MIKMIDINoteOffCommand *)command;
			NSNumber *noteNumber = @(noteOffCommand.note);
			MIKMutableMIDINoteEvent *noteEvent = self.pendingNotes[noteNumber];
			if (noteEvent) {
				noteEvent.releaseVelocity = noteOffCommand.velocity;
				MusicTimeStamp endTimeStamp = self.isLooping ? [sequence equivalentTimeStampForLoopedTimeStamp:self.currentTimeStamp] : self.currentTimeStamp;
				noteEvent.duration = endTimeStamp - noteEvent.timeStamp;
				[self.pendingNotes removeObjectForKey:noteNumber];
				[events addObject:noteEvent];
			}
		}
	}

	for (MIKMIDITrack *track in self.recordEnabledTracks) {
		[track insertMIDIEvents:events];
	}
}

@end
