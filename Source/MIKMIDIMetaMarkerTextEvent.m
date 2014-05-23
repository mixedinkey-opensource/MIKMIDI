//
//  MIKMIDIMetaMarkerTextEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaMarkerTextEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetaMarkerTextEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaMarkerText; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaMarkerTextEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaMarkerTextEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaMarkerTextEvent

+ (BOOL)isMutable { return YES; }

@end