//
//  MIKMIDIRecorder.h
//  MIKMIDI
//
//  Created by Chris Flesner on 11/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPlayer.h"

@class MIKMIDITrack;


@interface MIKMIDIRecorder : MIKMIDIPlayer

@property (readonly, nonatomic, getter=isRecording) BOOL recording;
@property (strong, nonatomic) NSSet *recordEnabledTracks;

@property (nonatomic, getter=isClickTrackEnabledInRecord) BOOL clickTrackEnabledInRecord;

- (void)prepareRecording;
- (void)startRecording;
- (void)startRecordingFromPosition:(MusicTimeStamp)position;
- (void)resumeRecording;
- (void)stopRecording;

- (void)recordMIDICommands:(NSSet *)commands;

@end
