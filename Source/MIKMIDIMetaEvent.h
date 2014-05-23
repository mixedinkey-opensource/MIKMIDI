//
//  MIKMIDIMetadataEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

#define MIKMIDIEventMetadataStartOffset 8

@interface MIKMIDIMetaEvent : MIKMIDIEvent

@property (nonatomic, readonly) UInt8 metadataType;
@property (nonatomic, readonly) UInt32 metadataLength;
@property (nonatomic, readonly) NSData *metaData;

@end

@interface MIKMutableMIDIMetaEvent : MIKMIDIMetaEvent

@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, readwrite) NSData *metaData;

@end