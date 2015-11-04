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

#if !__has_feature(objc_arc)
#error MIKMIDIMetaTimeSignatureEvent.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMetaTimeSignatureEvent.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetaTimeSignatureEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (NSArray *)supportedMIDIEventTypes { return @[@(MIKMIDIEventTypeMetaTimeSignature)]; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaTimeSignatureEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaTimeSignatureEvent class]; }
+ (BOOL)isMutable { return NO; }
+ (NSData *)initialData
{
	NSMutableData *superData = [[super initialData] mutableCopy];
	[superData increaseLengthBy:2]; // Account for numerator, denominator, metronome, and 32nd note bytes
	return [superData copy];
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"numerator"] ||
        [key isEqualToString:@"denominator"] ||
        [key isEqualToString:@"metronomePulse"] ||
        [key isEqualToString:@"thirtySecondsPerQuarterNote"]) {
        keyPaths = [keyPaths setByAddingObject:@"metaData"];
    }
    return keyPaths;
}

- (UInt8)numerator
{
    return *(UInt8*)[self.metaData bytes];
}

- (void)setNumerator:(UInt8)numerator
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = [self.metaData mutableCopy];
	if ([mutableMetaData length] < 1) [mutableMetaData increaseLengthBy:1];
    [mutableMetaData replaceBytesInRange:NSMakeRange(0, 1) withBytes:&numerator length:1];
    [self setMetaData:mutableMetaData];
}

- (UInt8)denominator
{
    UInt8 denominator = *((UInt8*)[self.metaData bytes] + 1);
    return (UInt8)pow(2.0, (float)denominator);
}

- (void)setDenominator:(UInt8)denominator
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = [self.metaData mutableCopy];
	if ([mutableMetaData length] < 2) [mutableMetaData increaseLengthBy:2-[mutableMetaData length]];
    UInt8 denominatorPower = log2(denominator);
    [mutableMetaData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&denominatorPower length:1];
    [self setMetaData:mutableMetaData];
}

- (UInt8)metronomePulse
{
    return *((UInt8*)[self.metaData bytes] + 2);
}

- (void)setMetronomePulse:(UInt8)metronomePulse
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = [self.metaData mutableCopy];
	if ([mutableMetaData length] < 3) [mutableMetaData increaseLengthBy:3-[mutableMetaData length]];
    [mutableMetaData replaceBytesInRange:NSMakeRange(2, 1) withBytes:&metronomePulse length:1];
    [self setMetaData:mutableMetaData];
}

- (UInt8)thirtySecondsPerQuarterNote
{
    return *((UInt8*)[self.metaData bytes] + 3);
}

- (void)setThirtySecondsPerQuarterNote:(UInt8)thirtySecondsPerQuarterNote
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = [self.metaData mutableCopy];
	if ([mutableMetaData length] < 4) [mutableMetaData increaseLengthBy:4-[mutableMetaData length]];
    [mutableMetaData replaceBytesInRange:NSMakeRange(3, 1) withBytes:&thirtySecondsPerQuarterNote length:1];
    [self setMetaData:mutableMetaData];
}

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"Numerator: %d, Denominator: %d, Pulse: %d, Thirty Seconds: %d", self.numerator, self.denominator, self.metronomePulse, self.thirtySecondsPerQuarterNote];
}

@end

@implementation MIKMutableMIDIMetaTimeSignatureEvent

@dynamic metadataType;
@dynamic metaData;
@dynamic timeStamp;
@dynamic numerator;
@dynamic denominator;
@dynamic metronomePulse;
@dynamic thirtySecondsPerQuarterNote;

+ (BOOL)isMutable { return YES; }

@end