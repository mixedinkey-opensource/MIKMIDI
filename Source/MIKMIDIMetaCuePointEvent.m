//
//  MIKMIDIMetaCuePointEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaCuePointEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetaCuePointEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaCuePoint; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaCuePointEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaCuePointEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaCuePointEvent
+ (BOOL)isMutable { return YES; }
@end
