//
//  MIKMIDIMetadataSequenceEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"

/**
 *  A meta event containing sequence information.
 */
@interface MIKMIDIMetaSequenceEvent : MIKMIDIMetaEvent

@end

/**
 *  The mutable counterpart of MIKMIDIMetaSequenceEvent.
 */
@interface MIKMutableMIDIMetaSequenceEvent : MIKMIDIMetaSequenceEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite) NSData *metaData;

@end
