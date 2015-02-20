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
@class MIKMIDITrack;
@class MIKMIDIMetronome;
@class MIKMIDICommand;
@class MIKMIDIDestinationEndpoint;

/**
 *  Types of click track statuses, that determine when the click track will be audible.
 *
 *  @see clickTrackStatus
 */
typedef NS_ENUM(NSInteger, MIKMIDISequencerClickTrackStatus) {
	/** The click track will not be heard during playback or recording. */
	MIKMIDISequencerClickTrackStatusDisabled,
	/** The click track will only be heard while recording. */
	MIKMIDISequencerClickTrackStatusEnabledInRecord,
	/** The click track will only be heard while recording and while the playback position is still in the pre-roll. */
	MIKMIDISequencerClickTrackStatusEnabledOnlyInPreRoll,
	/** The click track will always be heard during playback and recording. */
	MIKMIDISequencerClickTrackStatusAlwaysEnabled
};


/**
 *  MIKMIDISequencer can be used to play and record to an MIKMIDISequence.
 *
 *  @note MIKMIDISequencer currently only supports the playback and recording
 *  of MIDI note events. If you need to playback other events from a MIKMIDISequence, 
 *  use MIKMIDIPlayer for now, keeping in mind that once MIKMIDISequencer is 
 *  fully functional, MIKMIDIPlayer will be deprecated.
 */
@interface MIKMIDISequencer : NSObject

#pragma mark - Creation

/**
 *  Convenience method for creating a new MIKMIDISequencer instance with an empty sequence.
 *
 *  @return An initialized MIKMIDISequencer.
 */
+ (instancetype)sequencer;

/**
 *  Initializes and returns  a new MIKMIDISequencer ready to playback and record to the
 *  specified sequence.
 *
 *  @param sequence The sequence to playback and record to.
 *
 *  @return An initialized MIKMIDISequencer.
 */
- (instancetype)initWithSequence:(MIKMIDISequence *)sequence;

/**
 *  Convenience method for creating a new MIKMIDISequencer ready to playback and
 *  record to the specified sequence.
 *
 *  @param sequence The sequence to playback and record to.
 *
 *  @return An initialized MIKMIDISequencer.
 */
+ (instancetype)sequencerWithSequence:(MIKMIDISequence *)sequence;

#pragma mark - Playback

/**
 *  Starts playback from the beginning of the sequence.
 */
- (void)startPlayback;

/**
 *  Starts playback from the specified time stamp.
 *
 *  @param timeStamp The position in the sequence to begin playback from.
 */
- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp;

/**
 *  Starts playback from the specified MusicTimeStamp at the specified MIDITimeStamp.
 *  This could be useful if you need to synchronize the playback with another source
 *  such as an audio track, or another MIKMIDISequencer instance.
 *
 *  @param timeStamp The position in the sequence to begin playback from.
 *
 *  @param midiTimeStamp The MIDITimeStamp to begin playback at.
 */
- (void)startPlaybackAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

/**
 *  Starts playback from the position returned by -currentTimeStamp.
 *
 *  @see currentTimeStamp
 */
- (void)resumePlayback;

#pragma mark - Recording

/**
 *  Starts playback from the beginning of the sequence minus the value returned
 *  by -preRoll, and enables recording of incoming events to the record enabled tracks.
 *
 *  @see preRoll
 *  @see recordEnabledTracks
 */
- (void)startRecording;

/**
 *  Starts playback from the specified time stamp minus the value returned by
 *  -preRoll, and enables recording of incoming events to the record enabled tracks.
 *
 *  @see preRoll
 *  @see recordEnabledTracks
 */
- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp;

/**
 *  Starts playback from the specified MusicTimeStamp minus the value returned by -preRoll
 *  at the specified MIDITimeStamp, and enables recording of incoming events to the
 *  record enabled tracks.
 *
 *  @see preRoll
 *  @see recordEnabledTracks
 */
- (void)startRecordingAtTimeStamp:(MusicTimeStamp)timeStamp MIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

/**
 *  Starts playback from the position returned by -currentTimeStamp minus the
 *  value returned by -preRoll, and enables recording of incoming events to the
 *  record enabled tracks.
 *
 *  @see preRoll
 *  @see recordEnabledTracks
 */
- (void)resumeRecording;

/**
 *  Stops all playback and recording.
 */
- (void)stop;

/**
 *  Records a MIDI command to the record enabled tracks.
 *
 *  @param command The MIDI command to record to the record enabled tracks.
 *
 *  @note When recording is NO, calls to this method will do nothing.
 *
 *  @see recording
 *  @see recordEnabledTracks
 */
- (void)recordMIDICommand:(MIKMIDICommand *)command;

#pragma mark - Configuration

/**
 *  Sets the destination endpoint for a track in the sequencer's sequence.
 *  Calling this method is optional. By default, the sequencer will setup internal default endpoints
 *  so that playback "just works".
 *
 *  @note If track is not contained by the receiver's sequence, this method does nothing.
 *
 *  @param endpoint The MIKMIDIDestinationEndpoint instance to which events in track should be sent during playback.
 *  @param track    An MIKMIDITrack instance.
 */
- (void)setDestinationEndpoint:(MIKMIDIDestinationEndpoint *)endpoint forTrack:(MIKMIDITrack *)track;

/**
 *  Returns the destination endpoint for a track in the sequencer's sequence.
 *
 *  @note If track is not contained by the receiver's sequence, this method returns nil.
 *
 *  @param track An MIKMIDITrack instance.
 *
 *  @return The destination endpoint associated with track, or nil if one can't be found.
 */
- (MIKMIDIDestinationEndpoint *)destinationEndpointForTrack:(MIKMIDITrack *)track;

#pragma mark - Properties

/**
 *  The sequence to playback and record to.
 */
@property (strong, nonatomic) MIKMIDISequence *sequence;

/**
 *	Whether or not the sequencer is currently playing. This can be observed with KVO.
 *
 *  @see recording
 */
@property (readonly, nonatomic, getter=isPlaying) BOOL playing;

/**
 *  Whether or not the sequence is currently playing and is record enabled.
 *  This can be observed with KVO.
 *
 *  @note When recording is YES, events will only be recorded to the tracks
 *  specified by -recordEnabledTracks.
 *
 *  @see playing
 *  @see recordEnabledTracks
 */
@property (readonly, nonatomic, getter=isRecording) BOOL recording;

/**
 *  The current playback position in the sequence.
 */
@property (nonatomic) MusicTimeStamp currentTimeStamp;

/**
 *  The amount of time (in beats) to pre-roll the sequence before recording.
 *  For example, if preRoll is set to 4 and you begin recording, the sequence
 *  will start 4 beats ahead of the specified recording position.
 *
 *  The default is 4.
 */
@property (nonatomic) MusicTimeStamp preRoll;

/**
 *  Whether or not playback should loop when between loopStartTimeStamp and loopEndTimeStamp.
 *
 *  @see loopStartTimeStamp
 *  @see loopEndTimeStamp
 *  @see looping
 */
@property (nonatomic, getter=shouldLoop) BOOL loop;

/**
 *  Whether or not playback is currently looping between loopStartTimeStamp and loopEndTimeStamp.
 *
 *  @note If loop is YES, and playback starts before loopStartTimeStamp, looping will be NO until
 *  currentTimeStamp reaches loopStartTimeStamp. At that point, looped playback will begin and
 *  the looping property will become YES. Conversely, if playback starts after loopEndTimeStamp,
 *  then the looped area of playback will never be reached and looping will remain NO.
 *
 *  @see loop
 *  @see loopStartTimeStamp
 *  @see loopEndTimeStamp
 *  @see currentTimeStamp
 */
@property (readonly, nonatomic, getter=isLooping) BOOL looping;

/**
 *  The loop's beginning time stamp during looped playback.
 */
@property (nonatomic) MusicTimeStamp loopStartTimeStamp;

/**
 *  The loop's ending time stamp during looped playback.
 *
 *  @note To have the loop end at the end of the sequence, regardless of
 *  sequence length, set this value to less than 0. The default is -1.
 */
@property (nonatomic) MusicTimeStamp loopEndTimeStamp;

/**
 *  The metronome to send click track events to.
 */
@property (strong, nonatomic) MIKMIDIMetronome *metronome;

/**
 *  When the click track should be heard.
 *  The default is MIKMIDISequencerClickTrackStatusEnabledInRecord.
 */
@property (nonatomic) MIKMIDISequencerClickTrackStatus clickTrackStatus;

/**
 *  The tracks to record incoming MIDI events to while recording is enabled.
 *
 *  Each incoming event is added to every track in this set.
 *
 *  @see recording
 */
@property (copy, nonatomic) NSSet *recordEnabledTracks;

@end
