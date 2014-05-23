//
//  MIKMIDIMetaLyricEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaLyricEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetaLyricEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaLyricText; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaLyricEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaLyricEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaLyricEvent

+ (BOOL)isMutable { return YES; }

@end