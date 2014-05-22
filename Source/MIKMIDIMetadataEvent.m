//
//  MIKMIDIMetadataEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetadataEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMetadataEvent

+ (void)load { [MIKMIDIEvent registerSubclass:self]; }
+ (BOOL)supportsMusicEventType:(MusicEventType)type { return type == kMusicEventType_Meta; }
+ (Class)immutableCounterpartClass { return [MIKMIDIMetadataEvent class]; }
+ (Class)mutableCounterpartClass { return [MIKMutableMIDIMetadataEvent class]; }
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
    return [self.internalData subdataWithRange:NSMakeRange(8, metaEvent->dataLength)];
}

#warning Need method to set metadata (and it needs to set length and alter internalData as well

@end


@implementation MIKMutableMIDIMetadataEvent

@dynamic metadataType;
@dynamic metaData;

+ (BOOL)isMutable { return NO; }

@end