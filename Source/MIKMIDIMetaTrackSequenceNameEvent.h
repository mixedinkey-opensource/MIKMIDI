//
//  MIKMIDIMetaTrackSequenceNameEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTextEvent.h"

/**
 *  A meta event containing track sequence information.
 */
@interface MIKMIDIMetaTrackSequenceNameEvent : MIKMIDIMetaTextEvent

@end

/**
 *  The mutable counterpart of MIKMIDIMetaTrackSequenceNameEvent
 */
@interface MIKMutableMIDIMetaTrackSequenceNameEvent : MIKMIDIMetaTrackSequenceNameEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, readwrite) NSData *metaData;

@end