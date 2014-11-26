//
//  MIKMIDISequencer.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequencer.h"
#import "MIKMIDISequence.h"
#import "MIKMIDIClock.h"


#define MIKMIDISequencerDefaultTempo	120


@interface MIKMIDISequencer ()

@property (readonly, nonatomic) MIKMIDIClock *clock;

@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isRecording) BOOL recording;

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

}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp
{
	MIDITimeStamp midiTimeStamp = MIKMIDIGetCurrentTimeStamp() + [MIKMIDIClock midiTimeStampsPerTimeInterval:0.0005];
	[self startPlaybackAtTimeStamp:timeStamp MIDITimeStamp:midiTimeStamp];
}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{
	Float64 startingTempo;
	if (![self.sequence getTempo:&startingTempo atTimeStamp:timeStamp]) startingTempo = MIKMIDISequencerDefaultTempo;
	[self.clock setMusicTimeStamp:timeStamp withTempo:startingTempo atMIDITimeStamp:midiTimeStamp];

	self.playing = YES;
}

- (void)resumePlayback
{

}

- (void)stopPlayback
{
	self.playing = NO;
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

@end
