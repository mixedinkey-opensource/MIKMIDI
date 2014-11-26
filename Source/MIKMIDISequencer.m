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


@interface MIKMIDISequencer ()

@property (readonly, nonatomic) MIKMIDIClock *clock;

@property (nonatomic, getter=isPlaying) BOOL playing;
@property (nonatomic, getter=isRecording) BOOL recording;

@end


@implementation MIKMIDISequencer

#pragma mark - Lifecycle

- (instancetype)init
{
	if (self = [super init]) {
		_clock = [MIKMIDIClock clock];
	}
	return self;
}

+ (instancetype)sequencer
{
	return [[self alloc] init];
}

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence
{
	if (self = [self init]) {
		self.sequence = sequence;
	}
	return self;
}

+ (instancetype)sequencerWithSequence:(MIKMIDISequence *)sequence
{
	return [[self alloc] initWithSequence:sequence];
}

#pragma mark - Playback

- (void)startPlayback
{

}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp
{

}

- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp
{

}

- (void)resumePlayback
{

}

- (void)stopPlayback
{

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
