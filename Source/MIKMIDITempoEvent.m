//
//  MIKMIDITempoEvent.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDITempoEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDITempoEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeExtendedTempo; }
+ (Class)immutableCounterpartClass { return [MIKMIDITempoEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDITempoEvent class]; }
+ (BOOL)isMutable { return NO; }

+ (instancetype)tempoEventWithTimeStamp:(MusicTimeStamp)timeStamp tempo:(Float64)bpm;
{
    ExtendedTempoEvent tempoEvent = { .bpm = bpm };
    NSData *data = [NSData dataWithBytes:&tempoEvent length:sizeof(tempoEvent)];
    return [self midiEventWithTimeStamp:timeStamp eventType:kMusicEventType_ExtendedTempo data:data];
}

- (NSString *)additionalEventDescription
{
	return [NSString stringWithFormat:@"tempo: %g BPM", self.bpm];
}

#pragma mark - Properties

- (Float64)bpm
{
	ExtendedTempoEvent *tempoEvent = (ExtendedTempoEvent *)[self.data bytes];
	return tempoEvent->bpm;
}

- (void)setBpm:(Float64)bpm
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	ExtendedTempoEvent *tempoEvent = (ExtendedTempoEvent *)[self.internalData bytes];
	[self willChangeValueForKey:@"internalData"];
	tempoEvent->bpm = bpm;
	[self didChangeValueForKey:@"internalData"];
}

@end

@implementation MIKMutableMIDITempoEvent

+ (BOOL)isMutable { return YES; }

@dynamic bpm;

@end