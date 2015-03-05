//
//  MIKMIDIMetaInstrumentNameEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTextEvent.h"

/**
 *  A meta event containing an instrument name.
 */
@interface MIKMIDIMetaInstrumentNameEvent : MIKMIDIMetaTextEvent

@end


/**
 *  The mutable counterpart of MIKMIDIMetaInstrumentNameEvent.
 */
@interface MIKMutableMIDIMetaInstrumentNameEvent : MIKMIDIMetaInstrumentNameEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite) NSData *metaData;

@end