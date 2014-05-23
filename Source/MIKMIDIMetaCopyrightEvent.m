//
//  MIKMIDIMetaCopyrightEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaCopyrightEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetaCopyrightEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaCopyright; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaCopyrightEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaCopyrightEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaCopyrightEvent

+ (BOOL)isMutable { return YES; }

@end