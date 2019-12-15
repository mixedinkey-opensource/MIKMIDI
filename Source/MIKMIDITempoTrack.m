//
//  MIKMIDITempoTrack.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 12/15/19.
//  Copyright © 2019 Mixed In Key. All rights reserved.
//

#import "MIKMIDITempoTrack.h"
#import "MIKMIDITrack_Protected.h"
#import "MIKMIDITempoEvent.h"

@interface MIKMIDITempoTrack ()

@property (nonatomic, copy) NSArray *tempoEventsCache;

@end

@implementation MIKMIDITempoTrack

- (void)updateTempoEventsCache
{
	self.tempoEventsCache = [self eventsOfClass:[MIKMIDITempoEvent class] fromTimeStamp:0 toTimeStamp:kMusicTimeStamp_EndOfTrack];
}

- (NSArray<MIKMIDITempoEvent *> *)tempoEvents
{
	[self dispatchSyncToSequencerProcessingQueueAsNeeded:^{
		if (!self.tempoEventsCache) {
			[self updateTempoEventsCache];
		}
	}];
	return self.tempoEventsCache;
}

- (void)setSortedEventsCache:(NSArray *)sortedEventsCache
{
	[super setSortedEventsCache:sortedEventsCache];
	[self updateTempoEventsCache];
}

@end
