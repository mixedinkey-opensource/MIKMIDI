//
//  MIKMIDIMetadataEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMetaEvent.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetaEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return type == MIKMIDIEventTypeMeta; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetaEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetaEvent class]; }
+ (BOOL)isMutable { return NO; }

- (NSString *)additionalEventDescription
{
    return [NSString stringWithFormat:@"Metadata Type: 0x%02x, Length: %u, Data: %@", self.metadataType, (unsigned int)self.metadataLength, self.metaData];
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingInternalData
{
	return [NSSet setWithObjects:@"metadataType", @"metadata", nil];
}

- (UInt8)metadataType
{
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    return metaEvent->metaEventType;
}

- (void)setMetadataType:(UInt8)metadataType
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    metaEvent->metaEventType = metadataType;
}

+ (NSSet *)keyPathsForValuesAffectingMetadataLength
{
	return [NSSet setWithObjects:@"metaData", nil];
}

- (UInt32)metadataLength
{
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    return metaEvent->dataLength;
}

- (NSData *)metaData
{
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    return [self.internalData subdataWithRange:NSMakeRange(MIKMIDIEventMetadataStartOffset, metaEvent->dataLength)];
}

- (void)setMetaData:(NSData *)metaData
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    metaEvent->dataLength = (UInt32)[metaData length];
    NSMutableData *newMetaData = [self.internalData subdataWithRange:NSMakeRange(0, MIKMIDIEventMetadataStartOffset)].mutableCopy;
    [newMetaData appendData:metaData];
    self.internalData = newMetaData;
}

@end


@implementation MIKMutableMIDIMetaEvent

@dynamic metadataType;
@dynamic metaData;

+ (BOOL)isMutable { return NO; }

@end