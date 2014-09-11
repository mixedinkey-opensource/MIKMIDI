//
//  MIKMIDIPlayer.h
//  MIKMIDI
//
//  Created by Chris Flesner on 9/8/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import "MIKMIDI.h"
#import "MIKMIDISequence.h"


@interface MIKMIDIPlayer : NSObject

@property (strong, nonatomic) MIKMIDISequence *sequence;
@property (nonatomic) MusicTimeStamp currentTimeStamp;
@property (nonatomic) Float64 tailDuration;

@property (readonly, nonatomic) BOOL isPlaying;
@property (nonatomic) BOOL loopPlayback;

@property (nonatomic) Float64 playRateScaler;

- (void)preparePlayback;
- (void)startPlayback;
- (void)startPlaybackFromPosition:(MusicTimeStamp)position;
- (void)resumePlayback;
- (void)stopPlayback;

@end
