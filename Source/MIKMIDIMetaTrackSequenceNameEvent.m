//
//  MIKMIDIMetaTrackSequenceNameEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTrackSequenceNameEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMetaTrackSequenceNameEvent.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetaTrackSequenceNameEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaTrackSequenceName; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaTrackSequenceNameEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaTrackSequenceNameEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaTrackSequenceNameEvent

+ (BOOL)isMutable { return YES; }

@end