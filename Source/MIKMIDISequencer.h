//
//  MIKMIDISequencer.h
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MIKMIDISequence;
@class MIKMIDIMetronome;
@class MIKMIDICommand;


@interface MIKMIDISequencer : NSObject

+ (instancetype)sequencer;

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence;
+ (instancetype)sequencerWithSequence:(MIKMIDISequence *)sequence;

@property (strong, nonatomic) MIKMIDISequence *sequence;
@property (readonly, nonatomic, getter=isPlaying) BOOL playing;
@property (readonly, nonatomic, getter=isRecording) BOOL recording;

@property (nonatomic) MusicTimeStamp currentTimeStamp;
@property (nonatomic) MusicTimeStamp preRoll;

@property (nonatomic, getter=isPunchInOutEnabled) BOOL punchInOutEnabled;
@property (nonatomic) MusicTimeStamp punchInTime;
@property (nonatomic) MusicTimeStamp punchOutTime;

@property (nonatomic, getter=shouldLoop) BOOL loop;
@property (readonly, nonatomic, getter=isLooping) BOOL looping;
@property (nonatomic) MusicTimeStamp loopStartTimeStamp;
@property (nonatomic) MusicTimeStamp loopEndTimeStamp;	// set to -1 to have the loop end at the end of the sequence. default is -1.

@property (strong, nonatomic) MIKMIDIMetronome *metronome;
@property (nonatomic, getter=isClickTrackAlwaysEnabled) BOOL clickTrackAlwaysEnabled;
@property (nonatomic, getter=isClickTrackEnabledInRecord) BOOL clickTrackEnabledInRecord;
@property (nonatomic, getter=isClickTrackEnabledInPreRoll) BOOL clickTrackEnabledInPreRoll;

@property (copy, nonatomic) NSSet *recordEnabledTracks;

- (void)startPlayback;
- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp;
- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp;
- (void)resumePlayback;
- (void)stopPlayback;

- (void)startRecording;
- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp;
- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp;
- (void)resumeRecording;
- (void)stopRecording;

- (void)recordMIDICommand:(MIKMIDICommand *)command;

@end
