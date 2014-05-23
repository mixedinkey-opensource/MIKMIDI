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
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMIDINoteMessage; }
+ (Class)immutableCounterpartClass { return [MIKMIDINoteEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDINoteEvent class]; }
+ (BOOL)isMutable { return NO; }

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingEndTimeStamp
{
	return [NSSet setWithObjects:@"musicTimeStamp", @"duration", nil];
}

- (UInt8)note
{
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    return noteMessage->note;
}

- (void)setNote:(UInt8)note
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDINoteMessage *noteMessage = (MIDINoteMessage*)[self.internalData bytes];
    [self willChangeValueForKey:@"note"];
    noteMessage->channel = note;
    [self willChangeValueForKey:@"note"];
}

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

- (MusicTimeStamp)endTimeStamp
{
	return self.musicTimeStamp + self.duration;
}

- (float)frequency
{
    //tuning based on A4 = 440 hz
    float A = 440.0;
    return (A / 32.0) * powf(2.0, (((float)self.note - 9.0) / 12.0));
}

- (NSString *)noteLetter
{
    NSArray *letters = @[@"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B"];
    return [letters objectAtIndex:self.note % 12];
}

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"MIDINote: %d, Note: %@, channel %d, duration %f, velocity %d, frequency %f", self.note, self.noteLetter, self.channel, self.duration, self.velocity, self.frequency];
}

@end


@implementation MIKMutableMIDINoteEvent

@dynamic note;
@dynamic velocity;
@dynamic releaseVelocity;
@dynamic duration;

+ (BOOL)isMutable { return YES; }

@end
