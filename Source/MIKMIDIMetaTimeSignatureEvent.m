//
//  MIKMIDITimeSignatureEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTimeSignatureEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetaTimeSignatureEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventType_MetaTimeSignature; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaTimeSignatureEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaTimeSignatureEvent class]; }
+ (BOOL)isMutable { return NO; }

@end

@implementation MIKMutableMIDIMetaTimeSignatureEvent

+ (BOOL)isMutable { return YES; }

@end