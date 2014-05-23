//
//  MIKMIDIEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

typedef NS_ENUM(NSUInteger, MIKMIDIEventType)
{
    MIKMIDIEventType_NULL,
	MIKMIDIEventType_ExtendedNote,
	MIKMIDIEventType_ExtendedTempo,
	MIKMIDIEventType_User,
	MIKMIDIEventType_MIDINoteMessage,
	MIKMIDIEventType_MIDIChannelMessage,
	MIKMIDIEventType_MIDIRawData,
	MIKMIDIEventType_Parameter,
	MIKMIDIEventType_AUPreset,
    MIKMIDIEventType_ExtendedControl,
    MIKMIDIEventType_Meta,
    MIKMIDIEventType_MetaSequence,
    MIKMIDIEventType_MetaText,
    MIKMIDIEventType_MetaCopyright,
    MIKMIDIEventType_MetaTrackSequenceName,
    MIKMIDIEventType_MetaInstrumentName,
    MIKMIDIEventType_MetaLyricText,
    MIKMIDIEventType_MetaMarkerText,
    MIKMIDIEventType_MetaCuePoint,
    MIKMIDIEventType_MetaMIDIChannelPrefix,
    MIKMIDIEventType_MetaEndOfTrack,
    MIKMIDIEventType_MetaTempoSetting,
    MIKMIDIEventType_MetaSMPTEOffset,
    MIKMIDIEventType_MetaTimeSignature,
    MIKMIDIEventType_MetaKeySignature,
    MIKMIDIEventType_MetaSequenceSpecificEvent
};

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

@interface MIKMIDIEvent : NSObject <NSCopying>

@property (nonatomic, readonly) MusicEventType eventType;
@property (nonatomic, readonly) UInt8 channel;
@property (nonatomic, readonly) MusicTimeStamp musicTimeStamp;
@property (nonatomic, readonly) NSData *data;

+ (instancetype)midiEventWithTimestamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data;

@end

@interface MIKMutableMIDIEvent : MIKMIDIEvent

@property (nonatomic, readwrite) MusicEventType eventType;
@property (nonatomic, strong, readwrite) NSMutableData *data;

@end