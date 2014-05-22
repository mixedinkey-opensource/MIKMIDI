//
//  MIKMIDIMetadataEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

typedef NS_ENUM(NSUInteger, MIKMIDIMetaEventType)
{
    MIKMIDIMetaEventSequenceNumber          = 0x00,
    MIKMIDIMetaEventTextEvent               = 0x01,
    MIKMIDIMetaEventCopyrightNotice         = 0x02,
    MIKMIDIMetaEventTrackSequenceName       = 0x03,
    MIKMIDIMetaEventInstrumentName          = 0x04,
    MIKMIDIMetaEventLyricText               = 0x05,
    MIKMIDIMetaEventMarkerText              = 0x06,
    MIKMIDIMetaEventCuePoint                = 0x07,
    MIKMIDIMetaEventMIDIChannelPrefix       = 0x20,
    MIKMIDIMetaEventEndOfTrack              = 0x2F,
    MIKMIDIMetaEventTempoSetting            = 0x51,
    MIKMIDIMetaEventSMPTEOffset             = 0x54,
    MIKMIDIMetaEventTimeSignature           = 0x58,
    MIKMIDIMetaEventKeySignature            = 0x59,
    MIKMIDIMetaEventSequencerSpecificEvent  = 0x7F
};

@interface MIKMIDIMetadataEvent : MIKMIDIEvent

@property (nonatomic, readonly) UInt8 metadataType;
@property (nonatomic, readonly) UInt32 metadataLength;
@property (nonatomic, readonly) NSData *metaData;

@end

@interface MIKMutableMIDIMetadataEvent : MIKMIDIMetadataEvent

@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, readwrite) NSData *metaData;

@end