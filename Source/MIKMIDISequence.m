//
//  MIKMIDISequence.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequence.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MIKMIDITrack.h"
#import "MIKMIDITempoEvent.h"
#import "MIKMIDIMetaTimeSignatureEvent.h"
#import "MIKMIDIDestinationEndpoint.h"


const MusicTimeStamp MIKMIDISequenceLongestTrackLength = -1;


@interface MIKMIDISequence ()

@property (nonatomic) MusicSequence musicSequence;
@property (strong, nonatomic) MIKMIDITrack *tempoTrack;
@property (strong, nonatomic) NSArray *tracks;

@end


@implementation MIKMIDISequence

#pragma mark - Lifecycle

+ (instancetype)sequence
{
    return [[self alloc] init];
}

- (instancetype)init
{
    MusicSequence sequence;
    OSStatus err = NewMusicSequence(&sequence);
    if (err) {
        NSLog(@"NewMusicSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return nil;
    }

    return [self initWithMusicSequence:sequence];
}

+ (instancetype)sequenceWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
    return [[self alloc] initWithFileAtURL:fileURL error:error];
}

- (instancetype)initWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
    NSData *data = [NSData dataWithContentsOfURL:fileURL options:0 error:error];
    return data ? [self initWithData:data] : nil;
}

+ (instancetype)sequenceWithData:(NSData *)data
{
    return [[self alloc] initWithData:data];
}

- (instancetype)initWithData:(NSData *)data
{
    MusicSequence sequence;
    OSStatus err = NewMusicSequence(&sequence);
    if (err) {
        NSLog(@"NewMusicSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return nil;
    }

    err = MusicSequenceFileLoadData(sequence, (__bridge CFDataRef)data, kMusicSequenceFile_MIDIType, 0);
    if (err) {
        NSLog(@"MusicSequenceFileLoadData() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return nil;
    }

    return [self initWithMusicSequence:sequence];
}

+ (instancetype)sequenceWithMusicSequence:(MusicSequence)musicSequence
{
    return [[self alloc] initWithMusicSequence:musicSequence];
}

- (instancetype)initWithMusicSequence:(MusicSequence)musicSequence
{
    if (self = [super init]) {
        OSStatus err = MusicSequenceSetUserCallback(musicSequence, MIKSequenceCallback, (__bridge void *)self);
        if (err) NSLog(@"MusicSequenceSetUserCallback() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        self.musicSequence = musicSequence;

        MusicTrack tempoTrack;
        err = MusicSequenceGetTempoTrack(musicSequence, &tempoTrack);
        if (err) NSLog(@"MusicSequenceGetTempoTrack() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        self.tempoTrack = [MIKMIDITrack trackWithSequence:self musicTrack:tempoTrack];

        UInt32 numTracks = 0;
        err = MusicSequenceGetTrackCount(musicSequence, &numTracks);
        if (err) NSLog(@"MusicSequenceGetTrackCount() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

        NSMutableArray *tracks = [NSMutableArray arrayWithCapacity:numTracks];

        for (UInt32 i = 0; i < numTracks; i++) {
            MusicTrack musicTrack;
            err = MusicSequenceGetIndTrack(musicSequence, i, &musicTrack);
            if (err) NSLog(@"MusicSequenceGetIndTrack() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            [tracks addObject:[MIKMIDITrack trackWithSequence:self musicTrack:musicTrack]];
        }
        self.tracks = tracks;
        self.length = MIKMIDISequenceLongestTrackLength;
    }

    return self;
}

- (void)dealloc
{
    self.callBackBlock = nil;
    OSStatus err = DisposeMusicSequence(_musicSequence);
    if (err) NSLog(@"DisposeMusicSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

#pragma mark - Adding and Removing Tracks

- (MIKMIDITrack *)addTrack
{
    MusicTrack musicTrack;
    OSStatus err = MusicSequenceNewTrack(self.musicSequence, &musicTrack);
    if (err) {
        NSLog(@"MusicSequenceNewTrack() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return nil;
    }

    MIKMIDITrack *track = [MIKMIDITrack trackWithSequence:self musicTrack:musicTrack];

    if (track) {
        NSMutableArray *tracks = [self.tracks mutableCopy];
        [tracks addObject:track];
        self.tracks = tracks;
    }

    return track;
}

- (BOOL)removeTrack:(MIKMIDITrack *)track
{
    OSStatus err = MusicSequenceDisposeTrack(self.musicSequence, track.musicTrack);
    if (err) {
        NSLog(@"MusicSequenceDisposeTrack() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return NO;
    }

    NSMutableArray *tracks = [self.tracks mutableCopy];
    [tracks removeObject:track];
    self.tracks = tracks;

    return YES;
}

#pragma mark - File Saving

- (BOOL)writeToURL:(NSURL *)fileURL error:(NSError *__autoreleasing *)error
{
    return [self.dataValue writeToURL:fileURL options:NSDataWritingAtomic error:error];
}

#pragma mark - Callback

static void MIKSequenceCallback(void *inClientData, MusicSequence inSequence, MusicTrack inTrack, MusicTimeStamp inEventTime, const MusicEventUserData *inEventData, MusicTimeStamp inStartSliceBeat, MusicTimeStamp inEndSliceBeat)
{
    MIKMIDISequence *self = (__bridge MIKMIDISequence *)inClientData;
    if (!self.callBackBlock) return;

    UInt32 trackIndex;
    OSStatus err = MusicSequenceGetTrackIndex(inSequence, inTrack, &trackIndex);
    if (err) {
        NSLog(@"MusicSequenceGetTrackIndex() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return;
    }

    MIKMIDITrack *track = self.tracks[trackIndex];
    if (track && self.callBackBlock) {
        self.callBackBlock(track, inEventTime, inEventData, inStartSliceBeat, inEndSliceBeat);
    }
}

#pragma mark - Looping

- (MusicTimeStamp)equivalentTimeStampForLoopedTimeStamp:(MusicTimeStamp)loopedTimeStamp
{
    MusicTimeStamp length = self.length;

    if (loopedTimeStamp > length) {
        NSInteger numTimesLooped = loopedTimeStamp / length;
        loopedTimeStamp -= (length * numTimesLooped);
    }

    return loopedTimeStamp;
}

#pragma mark - Tempo

- (NSArray *)tempoEvents
{
    return [self.tempoTrack eventsOfClass:[MIKMIDITempoEvent class] fromTimeStamp:0 toTimeStamp:kMusicTimeStamp_EndOfTrack];
}

- (BOOL)setOverallTempo:(Float64)bpm
{
	NSArray *timeSignatureEvents = [self timeSignatureEvents];
    if (![self.tempoTrack clearAllEvents]) return NO;
	if (timeSignatureEvents.count && ![self.tempoTrack insertMIDIEvents:[NSSet setWithArray:timeSignatureEvents]]) return NO;
    return [self setTempo:bpm atTimeStamp:0];
}

- (BOOL)setTempo:(Float64)bpm atTimeStamp:(MusicTimeStamp)timeStamp
{
    MIKMIDITempoEvent *event = [MIKMIDITempoEvent tempoEventWithTimeStamp:timeStamp tempo:bpm];
    return [self.tempoTrack insertMIDIEvent:event];
}

- (BOOL)getTempo:(Float64 *)bpm atTimeStamp:(MusicTimeStamp)timeStamp
{
	if (!bpm) return NO;
    NSArray *events = [self.tempoTrack eventsOfClass:[MIKMIDITempoEvent class] fromTimeStamp:0 toTimeStamp:timeStamp];
    if (!events.count) return NO;

    MIKMIDITempoEvent *event = [events lastObject];
    *bpm = event.bpm;
    return YES;
}

#pragma mark - Time Signature

- (NSArray *)timeSignatureEvents
{
	return [self.tempoTrack eventsOfClass:[MIKMIDIMetaTimeSignatureEvent class] fromTimeStamp:0 toTimeStamp:kMusicTimeStamp_EndOfTrack];
}


- (BOOL)setOverallTimeSignature:(MIKMIDITimeSignature)signature
{
	NSArray *tempoEvents = [self tempoEvents];
	if (![self.tempoTrack clearAllEvents]) return NO;
	if (tempoEvents.count && ![self.tempoTrack insertMIDIEvents:[NSSet setWithArray:tempoEvents]]) return NO;
	return [self setTimeSignature:signature atTimeStamp:0];
}

- (BOOL)setTimeSignature:(MIKMIDITimeSignature)signature atTimeStamp:(MusicTimeStamp)timeStamp
{
	MIKMutableMIDIMetaTimeSignatureEvent *event = [[MIKMutableMIDIMetaTimeSignatureEvent alloc] init];
	event.timeStamp = timeStamp;
	event.numerator = signature.numerator;
	event.denominator = signature.denominator;
	event.metronomePulse = self.tempoTrack.timeResolution;
	event.thirtySecondsPerQuarterNote = 8;
	return [self.tempoTrack insertMIDIEvent:event];
}

- (BOOL)getTimeSignature:(MIKMIDITimeSignature *)signature atTimeStamp:(MusicTimeStamp)timeStamp
{
	if (!signature) return NO;
	NSArray *events = [self.tempoTrack eventsOfClass:[MIKMIDIMetaTimeSignatureEvent class] fromTimeStamp:0 toTimeStamp:timeStamp];
	if (!events.count) {
		signature->numerator = 4;
		signature->denominator = 4;
		return YES;
	};

	MIKMIDIMetaTimeSignatureEvent *event = [events lastObject];
	signature->numerator = event.numerator;
	signature->denominator = event.denominator;
	return YES;
}

#pragma mark - Description

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ tempo track: %@ tracks: %@", [super description], self.tempoTrack, self.tracks];
}

#pragma mark - Properties

- (MusicTimeStamp)length
{
    if (_length != MIKMIDISequenceLongestTrackLength) return _length;

    MusicTimeStamp length = 0;
    for (MIKMIDITrack *track in self.tracks) {
        MusicTimeStamp trackLength = track.length + track.offset;
        if (trackLength > length) length = trackLength;
    }

    return length;
}

- (Float64)durationInSeconds
{
    Float64 duration = 0;
    OSStatus err = MusicSequenceGetSecondsForBeats(self.musicSequence, self.length, &duration);
    if (err) NSLog(@"MusicSequenceGetSecondsForBeats() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return duration;
}

- (NSData *)dataValue
{
    CFDataRef data;
    OSStatus err = MusicSequenceFileCreateData(self.musicSequence, kMusicSequenceFile_MIDIType, 0, 0, &data);
    if (err) {
        NSLog(@"MusicSequenceFileCreateData() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        return nil;
    }

    return (__bridge_transfer NSData *)data;
}

- (void)setDestinationEndpoint:(MIKMIDIDestinationEndpoint *)destinationEndpoint
{
    for (MIKMIDITrack *track in self.tracks) {
        track.destinationEndpoint = destinationEndpoint;
    }
}

@end
