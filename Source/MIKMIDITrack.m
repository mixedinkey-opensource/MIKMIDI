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

- (instancetype)initWithMusicTrack:(MusicTrack *)musicTrack;
{
	self = [super init];
	if (self) {
		_musicTrack = musicTrack;
        
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



- (void)cleanup
{
	_musicTrack = NULL;
}

@end
