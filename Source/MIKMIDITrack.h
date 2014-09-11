//
//  MIKMIDITrack.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MIKMIDISequence;
@class MIKMIDIEvent;
@class MIKMIDINoteEvent;

@interface MIKMIDITrack : NSObject

- (instancetype)initWithSequence:(MIKMIDISequence *)sequence musicTrack:(MusicTrack)musicTrack;
+ (instancetype)trackWithSequence:(MIKMIDISequence *)sequence musicTrack:(MusicTrack)musicTrack;

@property (weak, nonatomic, readonly) MIKMIDISequence *sequence;
@property (nonatomic, readonly) MusicTrack musicTrack;

@property (nonatomic, copy) NSArray *events;      // all events
@property (nonatomic, readonly) NSArray *notes;   // only note events

@property (nonatomic, readonly) BOOL doesLoop;
@property (nonatomic) SInt32 numberOfLoops;
@property (nonatomic) MusicTimeStamp loopDuration;
@property (nonatomic) MusicTrackLoopInfo loopInfo;

@property (nonatomic) MusicTimeStamp offset;

@property (nonatomic, getter = isMuted) BOOL muted;
@property (nonatomic, getter = isSolo) BOOL solo;

@property (nonatomic) MusicTimeStamp length;

@property (nonatomic, readonly) SInt16 timeResolution;

- (BOOL)insertMIDIEvent:(MIKMIDIEvent *)event;
- (BOOL)removeMIDIEvent:(MIKMIDIEvent *)event;

- (BOOL)insertMIDIEvents:(NSSet *)events;
- (BOOL)removeMIDIEvents:(NSSet *)events;

- (BOOL)clearAllEvents;

- (NSArray *)eventsFromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp;
- (NSArray *)notesFromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp;

- (BOOL)moveEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp byAmount:(MusicTimeStamp)offsetTimeStamp;
- (BOOL)clearEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp;
- (BOOL)cutEventsFromStartingTimeStamp:(MusicTimeStamp)startTimeStamp toEndingTimeStamp:(MusicTimeStamp)endTimeStamp;

- (BOOL)copyEventsFromMIDITrack:(MIKMIDITrack *)origTrack fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp andInsertAtTimeStamp:(MusicTimeStamp)destTimeStamp;
- (BOOL)mergeEventsFromMIDITrack:(MIKMIDITrack *)origTrack fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp atTimeStamp:(MusicTimeStamp)destTimeStamp;

@end
