//
//  MIKMIDIMetadataEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

#define MIKMIDIEventMetadataStartOffset 8

/**
 *  A MIDI meta event.
 */
@interface MIKMIDIMetaEvent : MIKMIDIEvent

/**
 *  The type of metadata. See MIDIMetaEvent for more information.
 */
@property (nonatomic, readonly) UInt8 metadataType;

/**
 *  The length of the metadata. See MIDIMetaEvent for more information.
 */
@property (nonatomic, readonly) UInt32 metadataLength;

/**
 *  The metadata for the event.
 */
@property (nonatomic, readonly) NSData *metaData;

@end


/**
 *  The mutable counterpart of MIKMIDIMetaEvent.
 */
@interface MIKMutableMIDIMetaEvent : MIKMIDIMetaEvent

@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, readwrite) NSData *metaData;

@end