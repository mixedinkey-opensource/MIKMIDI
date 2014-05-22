//
//  MIKMIDIEventMIDINoteMessage.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDINoteEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDINoteEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMusicEventType:(MusicEventType)type { return type == kMusicEventType_MIDINoteMessage; }
+ (Class)immutableCounterpartClass { return [MIKMIDINoteEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDINoteEvent class]; }
+ (BOOL)isMutable { return NO; }

- (UInt8)channel
{
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    return noteMessage->channel;
}

- (void)setChannel:(UInt8)channel
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    [self willChangeValueForKey:@"channel"];
    noteMessage->channel = channel;
    [self willChangeValueForKey:@"channel"];
}


- (UInt8)velocity
{
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    return noteMessage->velocity;
}

- (void)setVelocity:(UInt8)velocity
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    [self willChangeValueForKey:@"velocity"];
    noteMessage->velocity = velocity;
    [self willChangeValueForKey:@"velocity"];
}


- (UInt8)releaseVelocity
{
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    return noteMessage->releaseVelocity;
}

- (void)setReleaseVelocity:(UInt8)releaseVelocity
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    [self willChangeValueForKey:@"releaseVelocity"];
    noteMessage->releaseVelocity = releaseVelocity;
    [self willChangeValueForKey:@"releaseVelocity"];
}


- (Float32)duration
{
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    return noteMessage->duration;
}

- (void)setDuration:(Float32)duration
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    [self willChangeValueForKey:@"duration"];
    noteMessage->duration = duration;
    [self willChangeValueForKey:@"duration"];
}

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"Note: %d, channel %d, duration %f, velocity %d", self.note, self.channel, self.duration, self.velocity];
}

@end


@implementation MIKMutableMIDINoteEvent

+ (BOOL)isMutable { return YES; }

@end
