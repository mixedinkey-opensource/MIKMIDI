//
//  MIKMIDIMetaKeySignatureEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaKeySignatureEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMetaKeySignatureEvent.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetaKeySignatureEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMetaKeySignature; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaKeySignatureEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaKeySignatureEvent class]; }
+ (BOOL)isMutable { return NO; }

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    if ([key isEqualToString:@"key"] || [key isEqualToString:@"scale"]) {
        keyPaths = [keyPaths setByAddingObject:@"metaData"];
    }
    return keyPaths;
}

- (UInt8)key
{
    return *(UInt8*)[self.metaData bytes];
}

- (void)setKey:(NSString *)key
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    [mutableMetaData replaceBytesInRange:NSMakeRange(0, 1) withBytes:&key length:1];
    [self setMetaData:[mutableMetaData copy]];
}

- (UInt8)scale
{
    return *((UInt8*)[self.metaData bytes] + 1);
}

- (void)setScale:(UInt8)scale
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    NSMutableData *mutableMetaData = self.metaData.mutableCopy;
    [mutableMetaData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&scale length:1];
    [self setMetaData:[mutableMetaData copy]];
}

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"Metadata Type: 0x%02x, Key: %d, Scale %d", self.metadataType, self.key, self.scale];
}

@end

@implementation MIKMutableMIDIMetaKeySignatureEvent

+ (BOOL)isMutable { return YES; }

@dynamic key;
@dynamic scale;

@end