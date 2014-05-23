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

- (UInt8)metadataType
{
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    return metaEvent->metaEventType;
}

- (void)setMetadataType:(UInt8)metadataType
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
    
    MIDIMetaEvent *metaEvent = (MIDIMetaEvent*)[self.internalData bytes];
    [self willChangeValueForKey:@"metadataType"];
    metaEvent->metaEventType = metadataType;
    [self willChangeValueForKey:@"metadataType"];
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
    [self willChangeValueForKey:@"metaData"];
    metaEvent->dataLength = (UInt32)[metaData length];
    NSMutableData *newMetaData = [self.internalData subdataWithRange:NSMakeRange(0, MIKMIDIEventMetadataStartOffset)].mutableCopy;
    [newMetaData appendData:metaData];
    self.internalData = newMetaData;
    [self didChangeValueForKey:@"metaData"];
}

@end


@implementation MIKMutableMIDIMetaEvent

@dynamic metadataType;
@dynamic metaData;

+ (BOOL)isMutable { return NO; }

@end