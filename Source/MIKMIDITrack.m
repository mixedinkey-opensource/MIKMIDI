//
//  MIKMIDITrack.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDITrack.h"

@implementation MIKMIDITrack
{
	MusicTrack *_musicTrack;
}

- (instancetype)initWithMusicTrack:(MusicTrack)musicTrack;
{
	self = [super init];
	if (self) {

		_musicTrack = malloc(sizeof(MusicTrack));
		memcpy(_musicTrack, &musicTrack, sizeof(MusicTrack));
        
        MusicEventIterator iterator = NULL;
        NewMusicEventIterator(*(_musicTrack), &iterator);

        MusicTimeStamp timestamp = 0;
        MusicEventType eventType = 0;
        const void *eventData = NULL;
        UInt32 eventDataSize = 0;
        Boolean hasNext = YES;
        
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &eventData, &eventDataSize);
            if (eventType == kMusicEventType_MIDINoteMessage) {
                MIDINoteMessage *noteMessage = (MIDINoteMessage*)eventData;
                printf("Note - timestamp: %6.3f, channel: %d, note: %d, velocity: %d, release velocity: %d, duration: %f\n",
                       timestamp,
                       noteMessage->channel,
                       noteMessage->note,
                       noteMessage->velocity,
                       noteMessage->releaseVelocity,
                       noteMessage->duration
                       );
            }
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
	}
	return self;
}

- (void)dealloc
{
    if (_musicTrack) free(_musicTrack);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ length: %f loop duration: %f number of loops: %li solo? %i muted? %i", [super description], self.length, self.loopDuration, (long)self.numberOfLoops, self.isSolo, self.isMuted];
}

#pragma mark - Properties

- (BOOL)doesLoop
{
	MusicTrackLoopInfo loopInfo;
	UInt32 loopInfoLength = sizeof(MusicTrackLoopInfo);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_LoopInfo, (void *)&loopInfo, &loopInfoLength);
	if (err) {
		NSLog(@"Unable to get loop info for track %@: %i", self, err);
		return NO;
	}
	return loopInfo.loopDuration > 0.0;
}

- (NSInteger)numberOfLoops
{
	MusicTrackLoopInfo loopInfo;
	UInt32 loopInfoLength = sizeof(MusicTrackLoopInfo);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_LoopInfo, (void *)&loopInfo, &loopInfoLength);
	if (err) {
		NSLog(@"Unable to get loop info for track %@: %i", self, err);
		return 0;
	}
	return loopInfo.numberOfLoops;
}

- (MusicTimeStamp)loopDuration
{
	MusicTrackLoopInfo loopInfo;
	UInt32 loopInfoLength = sizeof(MusicTrackLoopInfo);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_LoopInfo, (void *)&loopInfo, &loopInfoLength);
	if (err) {
		NSLog(@"Unable to get loop info for track %@: %i", self, err);
		return NO;
	}
	return (MusicTimeStamp)loopInfo.loopDuration;
}

- (BOOL)isMuted
{
	Boolean result = false;
	UInt32 resultLength = sizeof(result);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_MuteStatus, (void *)&result, &resultLength);
	if (err) {
		NSLog(@"Unable to get mute status for track %@: %i", self, err);
		return NO;
	}
	return (result != false);
}

- (BOOL)isSolo
{
	Boolean result = false;
	UInt32 resultLength = sizeof(result);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_SoloStatus, (void *)&result, &resultLength);
	if (err) {
		NSLog(@"Unable to get solo status for track %@: %i", self, err);
		return NO;
	}
	return (result != false);
}

- (MusicTimeStamp)length
{
	MusicTimeStamp result = 0;
	UInt32 resultLength = sizeof(result);
	OSStatus err = MusicTrackGetProperty(*_musicTrack, kSequenceTrackProperty_TrackLength, (void *)&result, &resultLength);
	if (err) {
		NSLog(@"Unable to get track length for track %@: %i", self, err);
		return NO;
	}
	return result;
}

@end
