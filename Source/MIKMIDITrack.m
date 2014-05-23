//
//  MIKMIDITrack.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDITrack.h"
#import "MIKMIDIEvent.h"
#import "MIKMIDINoteEvent.h"

@interface MIKMIDITrack()

@property (nonatomic, readwrite) BOOL doesLoop;
@property (nonatomic, readwrite) NSInteger numberOfLoops; // 0 means loops forever
@property (nonatomic, readwrite) MusicTimeStamp loopDuration;

@property (nonatomic, readwrite, getter = isMuted) BOOL muted;
@property (nonatomic, readwrite, getter = isSolo) BOOL solo;

@property (nonatomic, readwrite) MusicTimeStamp length;
@property (nonatomic, readwrite, copy) NSArray *events;

@end

@implementation MIKMIDITrack

- (instancetype)initWithMusicTrack:(MusicTrack)musicTrack;
{
	self = [super init];
	if (self) {

        MusicEventIterator iterator = NULL;
        NewMusicEventIterator(musicTrack, &iterator);

		MusicTrackLoopInfo loopInfo;
		UInt32 loopInfoLength = sizeof(MusicTrackLoopInfo);
		OSStatus err = MusicTrackGetProperty(musicTrack, kSequenceTrackProperty_LoopInfo, (void *)&loopInfo, &loopInfoLength);
		if (err) {
			NSLog(@"Unable to get loop info for track %@: %i", self, err);
			return NO;
		}
		self.doesLoop = loopInfo.loopDuration > 0.0;
		self.numberOfLoops = loopInfo.numberOfLoops;
		self.loopDuration = loopInfo.loopDuration;
		
		Boolean muteStatus = false;
		UInt32 muteStatusLength = sizeof(muteStatus);
		err = MusicTrackGetProperty(musicTrack, kSequenceTrackProperty_MuteStatus, (void *)&muteStatus, &muteStatusLength);
		if (err) {
			NSLog(@"Unable to get mute status for track %@: %i", self, err);
			return NO;
		}
		self.muted = (muteStatus != false);
		
		Boolean soloStatus = false;
		UInt32 soloStatusLength = sizeof(soloStatus);
		err = MusicTrackGetProperty(musicTrack, kSequenceTrackProperty_SoloStatus, (void *)&soloStatus, &soloStatusLength);
		if (err) {
			NSLog(@"Unable to get solo status for track %@: %i", self, err);
			return NO;
		}
		self.solo = (soloStatus != false);
		
		MusicTimeStamp lengthInfo = 0;
		UInt32 lengthInfoLength = sizeof(lengthInfo);
		err = MusicTrackGetProperty(musicTrack, kSequenceTrackProperty_TrackLength, (void *)&lengthInfo, &lengthInfoLength);
		if (err) {
			NSLog(@"Unable to get track length for track %@: %i", self, err);
			return NO;
		}
		self.length = lengthInfo;
		
        MusicTimeStamp timestamp = 0;
        MusicEventType eventType = 0;
        const void *rawEventData = NULL;
        UInt32 eventDataSize = 0;
        Boolean hasNext = YES;
        NSMutableArray *midiEvents = [NSMutableArray array];
        MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        while (hasNext) {
            MusicEventIteratorGetEventInfo(iterator, &timestamp, &eventType, &rawEventData, &eventDataSize);
           
            NSData *eventData = [[NSData alloc] initWithBytes:rawEventData length:eventDataSize];
            MIKMIDIEvent *event = [MIKMIDIEvent midiEventWithTimestamp:timestamp eventType:eventType data:eventData];
            [midiEvents addObject:event];
            
            MusicEventIteratorNextEvent(iterator);
            MusicEventIteratorHasCurrentEvent(iterator, &hasNext);
        }
        self.events = midiEvents;
		
		if (!lengthInfo) {
			// Track length wasn't specified, so determine it from the last event
			NSArray *notes = [midiEvents filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
				return [evaluatedObject isKindOfClass:[MIKMIDINoteEvent class]];
			}]];
			NSSortDescriptor *timeSort = [NSSortDescriptor sortDescriptorWithKey:@"endTimeStamp" ascending:YES];
			notes = [notes sortedArrayUsingDescriptors:@[timeSort]];
			MIKMIDINoteEvent *lastNote = [notes lastObject];
			
			self.length = lastNote.endTimeStamp;
		}
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ length: %f loop duration: %f number of loops: %li solo? %i muted? %i events: %@", [super description], self.length, self.loopDuration, (long)self.numberOfLoops, self.isSolo, self.isMuted, self.events];
}

#pragma mark - Properties

@end
