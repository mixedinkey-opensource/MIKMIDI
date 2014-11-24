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

@class MIKMIDISequence;

/**
 *  MIKMIDIPlayer is an Objective-C wrapper for CoreMIDI's MusicPlayer.
 */
@interface MIKMIDIPlayer : NSObject

/**
 *  Prepares the MusicPlayer for playback.
 *
 *  Call this method in advance of playback to reduce a music player’s startup latency.
 */
- (void)preparePlayback;

/**
 *  Starts playback from the beginning of the music sequence. 
 *  Equivalent to calling -startPlaybackFromPosition with a position of 0.
 */
- (void)startPlayback;

/**
 *  Starts playback of the music sequence from the specified position.
 *
 *  @param position The MusicTimeStamp to begin playback from.
 */
- (void)startPlaybackFromPosition:(MusicTimeStamp)position;

/**
 *  Resumes playback of the music sequence from the MusicTimeStamp that the player last stopped at.
 */
- (void)resumePlayback;

/**
 *  Stops playback of the music seuqenece.
 */
- (void)stopPlayback;

/**
 *  The music sequence to play.
 */
@property (strong, nonatomic) MIKMIDISequence *sequence;

/**
 *  The current position in the music sequence.
 */
@property (nonatomic) MusicTimeStamp currentTimeStamp;

/**
 *  The additional amount of time in seconds to continue playing after the end of the last MIDI event in the sequence.
 *  The default is 0.
 */
@property (nonatomic) Float64 tailDuration;

/**
 *  Whether or not the player is currently playing. This property can be observed with KVO.
 */
@property (readonly, nonatomic) BOOL isPlaying;

/**
 *  Whether or not the player should loop playback of the music sequence.
 *
 *  @note MIKMIDI currently only supports looping of an entire music sequence. The results of looping a
 *  MIKMIDISequence that has a length shorter than the end of the last MIDI event in the sequence is undefined.
 */
@property (nonatomic, getter=isLooping) BOOL looping;

@property (nonatomic) BOOL stopPlaybackAtEndOfSequence;

@end
