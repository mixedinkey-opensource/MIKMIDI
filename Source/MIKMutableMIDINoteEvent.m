//
//  MIKMIDIEventMIDINoteMessage.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMutableMIDINoteEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"

@implementation MIKMIDINoteEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMusicEventType:(MusicEventType)type { return type == kMusicEventType_MIDINoteMessage; }
+ (Class)immutableCounterpartClass { return [MIKMIDINoteEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDINoteEvent class]; }
+ (BOOL)isMutable { return NO; }

@end


@implementation MIKMutableMIDINoteEvent

+ (BOOL)isMutable { return YES; }

@end
