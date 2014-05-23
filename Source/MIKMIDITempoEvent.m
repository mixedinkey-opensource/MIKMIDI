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

- (NSString *)additionalEventDescription
{
	return [NSString stringWithFormat:@"tempo: %f BPM", self.tempo];
}

#pragma mark - Properties

- (double)tempo
{
	ExtendedTempoEvent *tempoEvent = (ExtendedTempoEvent *)[self.data bytes];
	return (double)tempoEvent->bpm;
}

- (void)setTempo:(double)tempo
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	ExtendedTempoEvent *tempoEvent = (ExtendedTempoEvent *)[self.internalData bytes];
	[self willChangeValueForKey:@"internalData"];
	tempoEvent->bpm = tempo;
	[self didChangeValueForKey:@"internalData"];
}

@end

@implementation MIKMutableMIDITempoEvent

+ (BOOL)isMutable { return YES; }

@dynamic tempo;

@end