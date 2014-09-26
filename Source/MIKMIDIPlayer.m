//
//  MIKMIDIPlayer.m
//  MIKMIDI
//
//  Created by Chris Flesner on 9/8/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPlayer.h"
#import "MIKMIDITrack.h"
#import "MIKMIDISequence.h"
#import "MIKMIDIDestinationEndpoint.h"

@interface MIKMIDIPlayer ()

@property (nonatomic) MusicPlayer musicPlayer;
@property (nonatomic) BOOL isPlaying;

@property (strong, nonatomic) NSNumber *lastStoppedAtTimeStampNumber;

@property (strong, nonatomic) NSDate *lastPlaybackStartedTime;

@end


@implementation MIKMIDIPlayer

#pragma mark - Lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		MusicPlayer musicPlayer;
		OSStatus err = NewMusicPlayer(&musicPlayer);
		if (err) {
			NSLog(@"NewMusicPlayer() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
			return nil;
		}
		
		self.musicPlayer = musicPlayer;
	}
	return self;
}

- (void)dealloc
{
	if (self.isPlaying) [self stopPlayback];
	
	OSStatus err = DisposeMusicPlayer(_musicPlayer);
	if (err) NSLog(@"DisposeMusicPlayer() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

#pragma mark - Playback

- (void)preparePlayback
{
	OSStatus err = MusicPlayerPreroll(self.musicPlayer);
	if (err) NSLog(@"MusicPlayerPreroll() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (void)startPlayback
{
	[self startPlaybackFromPosition:0];
}

- (void)startPlaybackFromPosition:(MusicTimeStamp)position
{
	if (self.isPlaying) [self stopPlayback];
	
	[self loopTracksWhenNeeded];
	
	OSStatus err = MusicPlayerSetTime(self.musicPlayer, position);
	if (err) return NSLog(@"MusicPlayerSetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
	
	Float64 sequenceDuration = self.sequence.durationInSeconds;
	Float64 positionInTime;
	
	err = MusicSequenceGetSecondsForBeats(self.sequence.musicSequence, position, &positionInTime);
	if (err) return NSLog(@"MusicSequenceGetSecondsForBeats() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
	
	Float64 playbackDuration = (sequenceDuration - positionInTime) + self.tailDuration;
	if (playbackDuration <= 0) return;
	
	err = MusicPlayerStart(self.musicPlayer);
	if (err) return NSLog(@"MusicPlayerStart() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
	
	self.isPlaying = YES;
	NSDate *startTime = [NSDate date];
	self.lastPlaybackStartedTime = startTime;
	
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(playbackDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
		if ([startTime isEqualToDate:self.lastPlaybackStartedTime]) {
			if (!self.isLooping) {
				[self stopPlayback];
			}
		}
	});
}

- (void)resumePlayback
{
	if (!self.lastStoppedAtTimeStampNumber) return [self startPlayback];
	
	MusicTimeStamp lastTimeStamp = [self.lastStoppedAtTimeStampNumber doubleValue];
	lastTimeStamp = [self.sequence equivalentTimeStampForLoopedTimeStamp:lastTimeStamp];
	
	[self startPlaybackFromPosition:lastTimeStamp];
}

- (void)stopPlayback
{
	if (!self.isPlaying) return;
	
	Boolean musicPlayerIsPlaying = TRUE;
	OSStatus err = MusicPlayerIsPlaying(self.musicPlayer, &musicPlayerIsPlaying);
	if (err) {
		NSLog(@"MusicPlayerIsPlaying() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
	}
	
	self.lastStoppedAtTimeStampNumber = @(self.currentTimeStamp);
	
	if (musicPlayerIsPlaying) {
		err = MusicPlayerStop(self.musicPlayer);
		if (err) {
			NSLog(@"MusicPlayerStop() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
		}
	}
	
	[self unloopTracks];
	
	self.isPlaying = NO;
}

#pragma mark - Private

#pragma mark Looping

- (void)loopTracksWhenNeeded
{
	if (self.isLooping) {
		MusicTimeStamp length = self.sequence.length;
		MusicTrackLoopInfo loopInfo;
		loopInfo.numberOfLoops = 0;
		loopInfo.loopDuration = length;
		
		for (MIKMIDITrack *track in self.sequence.tracks) {
			[track setTemporaryLength:length andLoopInfo:loopInfo];
		}
	}
}

- (void)unloopTracks
{
	for (MIKMIDITrack *track in self.sequence.tracks) {
		[track restoreLengthAndLoopInfo];
	}
}

#pragma mark - Properties

- (void)setLooping:(BOOL)looping
{
	if (looping != _looping) {
		
		_looping = looping;
		
		if (self.isPlaying) {
			[self stopPlayback];
			[self preparePlayback];
			[self resumePlayback];
		}
	}
}

- (void)setSequence:(MIKMIDISequence *)sequence
{
	if (sequence != _sequence) {
		
		if (self.isPlaying) [self stopPlayback];
		
		MusicSequence musicSequence = sequence.musicSequence;
		OSStatus err = MusicPlayerSetSequence(self.musicPlayer, musicSequence);
		if (err) return NSLog(@"MusicPlayerSetSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
		
		_sequence = sequence;
	}
}

- (MusicTimeStamp)currentTimeStamp
{
	MusicTimeStamp position = 0;
	OSStatus err = MusicPlayerGetTime(self.musicPlayer, &position);
	if (err) NSLog(@"MusicPlayerGetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
	return position;
}

- (void)setCurrentTimeStamp:(MusicTimeStamp)currentTimeStamp
{
	OSStatus err = MusicPlayerSetTime(self.musicPlayer, currentTimeStamp);
	if (err) NSLog(@"MusicPlayerSetTime() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

@synthesize destinationEndpoint = _destinationEndpoint;

- (void)setDestinationEndpoint:(MIKMIDIDestinationEndpoint *)destinationEndpoint
{
	if (destinationEndpoint != _destinationEndpoint) {
		OSStatus err = MusicSequenceSetMIDIEndpoint(self.sequence.musicSequence, (MIDIEndpointRef)destinationEndpoint.objectRef);
		if (err) {
			NSLog(@"Unable to set Music Sequence MIDI Endpoint: %i", err);
		}
		_destinationEndpoint = destinationEndpoint;
	}
}

@end
