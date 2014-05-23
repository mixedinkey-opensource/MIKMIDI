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
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaTimeSignature; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaTimeSignatureEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaTimeSignatureEvent class]; }
+ (BOOL)isMutable { return NO; }

- (UInt8)numerator
{
    UInt8 *numeratorPointer = (UInt8*)[self.metaData bytes];
    return numeratorPointer[0];
}

- (void)setNumerator:(UInt8)numerator
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    [self willChangeValueForKey:@"numerator"];
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    [mutableMetaData replaceBytesInRange:NSMakeRange(0, 1) withBytes:&numerator];
    [self setMetaData:[mutableMetaData copy]];
    [self didChangeValueForKey:@"numerator"];
}

- (UInt8)denominator
{
    UInt8 *numeratorPointer = (UInt8*)[self.metaData bytes];
    return pow(2.0, (float)numeratorPointer[1]);
}

- (void)setDenominator:(UInt8)denominator
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    [self willChangeValueForKey:@"denominator"];
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    UInt8 denominatorPower = log2(denominator);
    [mutableMetaData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&denominatorPower];
    [self setMetaData:[mutableMetaData copy]];
    [self didChangeValueForKey:@"denominator"];
}

- (UInt8)metronomePulse
{
    UInt8 *numeratorPointer = (UInt8*)[self.metaData bytes];
    return numeratorPointer[2];
}

- (void)setMetronomePulse:(UInt8)metronomePulse
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    [self willChangeValueForKey:@"metronomePulse"];
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    [mutableMetaData replaceBytesInRange:NSMakeRange(2, 1) withBytes:&metronomePulse];
    [self setMetaData:[mutableMetaData copy]];
    [self didChangeValueForKey:@"metronomePulse"];
}

- (UInt8)thirtySecondsPerQuarterNote
{
    UInt8 *numeratorPointer = (UInt8*)[self.metaData bytes];
    return numeratorPointer[3];
}

- (void)setThirtySecondsPerQuarterNote:(UInt8)thirtySecondsPerQuarterNote
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    [self willChangeValueForKey:@"thirtySecondsPerQuarterNote"];
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    [mutableMetaData replaceBytesInRange:NSMakeRange(3, 1) withBytes:&thirtySecondsPerQuarterNote];
    [self setMetaData:[mutableMetaData copy]];
    [self didChangeValueForKey:@"thirtySecondsPerQuarterNote"];
}

@end

@implementation MIKMutableMIDIMetaTimeSignatureEvent

+ (BOOL)isMutable { return YES; }

@dynamic numerator;
@dynamic denominator;
@dynamic metronomePulse;
@dynamic thirtySecondsPerQuarterNote;

@end