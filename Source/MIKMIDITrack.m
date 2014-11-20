//
//  MIKMIDITrack.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequence.h"
#import "MIKMIDITrack.h"
#import "MIKMIDIEvent.h"
#import "MIKMIDINoteEvent.h"
#import "MIKMIDITempoEvent.h"
#import "MIKMIDIEventIterator.h"
#import "MIKMIDIDestinationEndpoint.h"

@interface MIKMIDITrack()

@property (weak, nonatomic) MIKMIDISequence *sequence;

@property (nonatomic) MusicTimeStamp restoredLength;
@property (nonatomic) MusicTrackLoopInfo restoredLoopInfo;
@property (nonatomic) BOOL hasTemporaryLengthAndLoopInfo;

@end


@implementation MIKMIDITrack

#pragma mark - Lifecycle

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence musicTrack:(MusicTrack)musicTrack
{
    if (self = [super init]) {
        MusicSequence musicTrackSequence;
        OSStatus err = MusicTrackGetSequence(musicTrack, &musicTrackSequence);
        if (err) NSLog(@"MusicTrackGetSequence() failed with error %d in %s.", err, __PRETTY_FUNCTION__);

        if (musicTrackSequence != sequence.musicSequence) {
            NSLog(@"ERROR: initWithSequence:musicTrack: requires the musicTrack's associated MusicSequence to be the same as sequence's musicSequence property.");
            return nil;
        }

        _musicTrack = musicTrack;
        _sequence = sequence;
    }

    return self;
}

+ (instancetype)trackWithSequence:(MIKMIDISequence *)sequence musicTrack:(MusicTrack)musicTrack
{
    return [[self alloc] initWithSequence:sequence musicTrack:musicTrack];
}

- (instancetype)init
{
#ifdef DEBUG
    @throw [NSException exceptionWithName:NSGenericException reason:@"Invalid initializer." userInfo:nil];
#endif
    return nil;
}

#pragma mark - Adding and Removing Events

- (BOOL)insertMIDIEvent:(MIKMIDIEvent *)event
{
    OSStatus err = noErr;
    MusicTrack track = self.musicTrack;
    MusicTimeStamp timeStamp = event.timeStamp;
    const void *data = [event.data bytes];

    switch (event.eventType) {
        case kMusicEventType_NULL:
            break;

        case kMusicEventType_ExtendedNote:
            err = MusicTrackNewExtendedNoteEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewExtendedNoteEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_ExtendedTempo:
            err = MusicTrackNewExtendedTempoEvent(track, timeStamp, ((ExtendedTempoEvent *)data)->bpm);
            if (err) NSLog(@"MusicTrackNewExtendedTempoEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_User:
            err = MusicTrackNewUserEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewUserEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_Meta:
            err = MusicTrackNewMetaEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewMetaEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_MIDINoteMessage:
            err = MusicTrackNewMIDINoteEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewMIDINoteEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_MIDIChannelMessage:
            err = MusicTrackNewMIDIChannelEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewMIDIChannelEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_MIDIRawData:
            err = MusicTrackNewMIDIRawDataEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewMIDIRawDataEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_Parameter:
            err = MusicTrackNewParameterEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewParameterEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;

        case kMusicEventType_AUPreset:
            err = MusicTrackNewAUPresetEvent(track, timeStamp, data);
            if (err) NSLog(@"MusicTrackNewAUPresetEvent() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
            break;
    }

    return !err;
}

- (BOOL)removeMIDIEvent:(MIKMIDIEvent *)event
{
    MusicTimeStamp timeStamp = event.timeStamp;
    NSMutableSet *events = [[self eventsFromTimeStamp:timeStamp toTimeStamp:timeStamp] mutableCopy];

    if ([events containsObject:event]) {
        [events removeObject:event];
        if (![self clearEventsFromStartingTimeStamp:timeStamp toEndingTimeStamp:timeStamp]) return NO;
        if (![self insertMIDIEvents:events]) return NO;;
    }

    return YES;
}

- (BOOL)insertMIDIEvents:(NSSet *)events
{
    for (MIKMIDIEvent *event in events) {
        if (![self insertMIDIEvent:event]) return NO;
    }
    return YES;
}

- (BOOL)removeMIDIEvents:(NSSet *)events
{
    for (MIKMIDIEvent *event in events) {
        if (![self removeMIDIEvent:event]) return NO;
    }
    return YES;
}

- (BOOL)clearAllEvents
{
    return [self clearEventsFromStartingTimeStamp:0 toEndingTimeStamp:kMusicTimeStamp_EndOfTrack];
}

#pragma mark - Getting Events

- (NSArray *)eventsFromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp
{
    return [self eventsOfClass:Nil fromTimeStamp:startTimeStamp toTimeStamp:endTimeStamp];
}

- (NSArray *)notesFromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp
{
    return [self eventsOfClass:[MIKMIDINoteEvent class] fromTimeStamp:startTimeStamp toTimeStamp:endTimeStamp];
}

- (NSArray *)eventsOfClass:(Class)eventClass fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp
{
    MIKMIDIEventIterator *iterator = [MIKMIDIEventIterator iteratorForTrack:self];
    if (![iterator seek:startTimeStamp]) return @[];

    NSMutableArray *events = [NSMutableArray array];

    while (iterator.hasCurrentEvent) {
        MIKMIDIEvent *event = iterator.currentEvent;
        if (!event || event.timeStamp > endTimeStamp) break;

        if (!eventClass || [event isKindOfClass:eventClass]) {
            [events addObject:event];
        }

        [iterator moveToNextEvent];
    }

    return events;
}

#pragma mark - Editing Events

- (BOOL)moveEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp byAmount:(MusicTimeStamp)offsetTimeStamp
{
    MusicTimeStamp length = self.length;
    if (!length || (startTimeStamp > length) || ![self.events count]) return YES;
    if (endTimeStamp > length) endTimeStamp = length;

    OSStatus err = MusicTrackMoveEvents(self.musicTrack, startTimeStamp, endTimeStamp, offsetTimeStamp);
    if (err) NSLog(@"MusicTrackMoveEvents() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

- (BOOL)clearEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp
{
    MusicTimeStamp length = self.length;
    if (!length || (startTimeStamp > length) || ![self.events count]) return YES;
    if (endTimeStamp > length) endTimeStamp = length;

    OSStatus err = MusicTrackClear(self.musicTrack, startTimeStamp, endTimeStamp);
    if (err) NSLog(@"MusicTrackClear() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

- (BOOL)cutEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp
{
    MusicTimeStamp length = self.length;
    if (!length || (startTimeStamp > length) || ![self.events count]) return YES;
    if (endTimeStamp > length) endTimeStamp = length;

    OSStatus err = MusicTrackCut(self.musicTrack, startTimeStamp, endTimeStamp);
    if (err) NSLog(@"MusicTrackCut() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

- (BOOL)copyEventsFromMIDITrack:(MIKMIDITrack *)origTrack fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp andInsertAtTimeStamp:(MusicTimeStamp)destTimeStamp
{
    MusicTimeStamp length = origTrack.length;
    if (!length || (startTimeStamp > length) || ![origTrack.events count]) return YES;
    if (endTimeStamp > length) endTimeStamp = length;

    OSStatus err = MusicTrackCopyInsert(origTrack.musicTrack, startTimeStamp, endTimeStamp, self.musicTrack, destTimeStamp);
    if (err) NSLog(@"MusicTrackCopyInsert() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

- (BOOL)mergeEventsFromMIDITrack:(MIKMIDITrack *)origTrack fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp atTimeStamp:(MusicTimeStamp)destTimeStamp
{
    MusicTimeStamp length = origTrack.length;
    if (!length || (startTimeStamp > length) || ![origTrack.events count]) return YES;
    if (endTimeStamp > length) endTimeStamp = length;

    OSStatus err = MusicTrackMerge(origTrack.musicTrack, startTimeStamp, endTimeStamp, self.musicTrack, destTimeStamp);
    if (err) NSLog(@"MusicTrackMerge() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

#pragma mark - Track Number

- (BOOL)getTrackNumber:(UInt32 *)trackNumber
{
    OSStatus err = MusicSequenceGetTrackIndex(self.sequence.musicSequence, self.musicTrack, trackNumber);
    if (err) NSLog(@"MusicSequenceGetTrackIndex() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return !err;
}

#pragma mark - Temporary Length and Loop Info

- (void)setTemporaryLength:(MusicTimeStamp)length andLoopInfo:(MusicTrackLoopInfo)loopInfo
{
    self.restoredLength = self.length;
    self.restoredLoopInfo = self.loopInfo;
    self.length = length;
    self.loopInfo = loopInfo;
    self.hasTemporaryLengthAndLoopInfo = YES;
}

- (void)restoreLengthAndLoopInfo
{
    if (!self.hasTemporaryLengthAndLoopInfo) return;

    self.hasTemporaryLengthAndLoopInfo = NO;
    self.length = self.restoredLength;
    self.loopInfo = self.restoredLoopInfo;
}


#pragma mark - Properties

- (void)setEvents:(NSArray *)events
{
    [self clearAllEvents];
    [self insertMIDIEvents:[NSSet setWithArray:events]];
}

- (NSArray *)events
{
    return [self eventsFromTimeStamp:0 toTimeStamp:kMusicTimeStamp_EndOfTrack];
}

- (NSArray *)notes
{
    return [self notesFromTimeStamp:0 toTimeStamp:kMusicTimeStamp_EndOfTrack];
}


- (BOOL)doesLoop
{
    return self.loopDuration > 0;
}

- (SInt32)numberOfLoops
{
    return self.loopInfo.numberOfLoops;
}

- (void)setNumberOfLoops:(SInt32)numberOfLoops
{
    MusicTrackLoopInfo loopInfo = self.loopInfo;

    if (loopInfo.numberOfLoops != numberOfLoops) {
        loopInfo.numberOfLoops = numberOfLoops;
        self.loopInfo = loopInfo;
    }
}

- (MusicTimeStamp)loopDuration
{
    return self.loopInfo.loopDuration;
}

- (void)setLoopDuration:(MusicTimeStamp)loopDuration
{
    MusicTrackLoopInfo loopInfo = self.loopInfo;

    if (loopInfo.loopDuration != loopDuration) {
        loopInfo.loopDuration = loopDuration;
        self.loopInfo = loopInfo;
    }
}

- (MusicTrackLoopInfo)loopInfo
{
    MusicTrackLoopInfo info;
    UInt32 infoSize = sizeof(info);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_LoopInfo, &info, &infoSize);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return info;
}

- (void)setLoopInfo:(MusicTrackLoopInfo)loopInfo
{
    OSStatus err = MusicTrackSetProperty(self.musicTrack, kSequenceTrackProperty_LoopInfo, &loopInfo, sizeof(loopInfo));
    if (err) NSLog(@"MusicTrackSetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (MusicTimeStamp)offset
{
    MusicTimeStamp offset = 0;
    UInt32 offsetLength = sizeof(offset);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_OffsetTime, &offset, &offsetLength);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return offset;
}

- (void)setOffset:(MusicTimeStamp)offset
{
    OSStatus err = MusicTrackSetProperty(self.musicTrack, kSequenceTrackProperty_OffsetTime, &offset, sizeof(offset));
    if (err) NSLog(@"MusicTrackSetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (BOOL)isMuted
{
    Boolean isMuted = FALSE;
    UInt32 isMutedLength = sizeof(isMuted);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_MuteStatus, &isMuted, &isMutedLength);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return isMuted ? YES : NO;
}

- (void)setMuted:(BOOL)muted
{
    Boolean mutedBoolean = muted ? TRUE : FALSE;
    OSStatus err = MusicTrackSetProperty(self.musicTrack, kSequenceTrackProperty_MuteStatus, &mutedBoolean, sizeof(mutedBoolean));
    if (err) NSLog(@"MusicTrackSetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (BOOL)isSolo
{
    Boolean isSolo = FALSE;
    UInt32 isSoloLength = sizeof(isSolo);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_SoloStatus, &isSolo, &isSoloLength);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return isSolo ? YES : NO;
}

- (void)setSolo:(BOOL)solo
{
    Boolean soloBoolean = solo ? TRUE : FALSE;
    OSStatus err = MusicTrackSetProperty(self.musicTrack, kSequenceTrackProperty_SoloStatus, &soloBoolean, sizeof(soloBoolean));
    if (err) NSLog(@"MusicTrackSetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (MusicTimeStamp)length
{
    MusicTimeStamp length = 0;
    UInt32 lengthLength = sizeof(length);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_TrackLength, &length, &lengthLength);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return length;
}

- (void)setLength:(MusicTimeStamp)length
{
    OSStatus err = MusicTrackSetProperty(self.musicTrack, kSequenceTrackProperty_TrackLength, &length, sizeof(length));
    if (err) NSLog(@"MusicTrackSetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
}

- (SInt16)timeResolution
{
    SInt16 resolution = 0;
    UInt32 resolutionLength = sizeof(resolution);
    OSStatus err = MusicTrackGetProperty(self.musicTrack, kSequenceTrackProperty_TimeResolution, &resolution, &resolutionLength);
    if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
    return resolution;
}

- (void)setDestinationEndpoint:(MIKMIDIDestinationEndpoint *)destinationEndpoint
{
    if (destinationEndpoint != _destinationEndpoint) {
        OSStatus err = MusicTrackSetDestMIDIEndpoint(self.musicTrack, (MIDIEndpointRef)destinationEndpoint.objectRef);
        if (err) NSLog(@"MusicTrackGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
        _destinationEndpoint = destinationEndpoint;
    }
}

@end
