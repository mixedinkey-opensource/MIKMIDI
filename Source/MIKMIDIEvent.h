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
    MIKMIDIEventTypeNULL,
	MIKMIDIEventTypeExtendedNote,
	MIKMIDIEventTypeExtendedTempo,
	MIKMIDIEventTypeUser,
	MIKMIDIEventTypeMIDINoteMessage,
	MIKMIDIEventTypeMIDIChannelMessage,
	MIKMIDIEventTypeMIDIRawData,
	MIKMIDIEventTypeParameter,
	MIKMIDIEventTypeAUPreset,
    MIKMIDIEventTypeExtendedControl,
    MIKMIDIEventTypeMeta,
    MIKMIDIEventTypeMetaSequence,
    MIKMIDIEventTypeMetaText,
    MIKMIDIEventTypeMetaCopyright,
    MIKMIDIEventTypeMetaTrackSequenceName,
    MIKMIDIEventTypeMetaInstrumentName,
    MIKMIDIEventTypeMetaLyricText,
    MIKMIDIEventTypeMetaMarkerText,
    MIKMIDIEventTypeMetaCuePoint,
    MIKMIDIEventTypeMetaMIDIChannelPrefix,
    MIKMIDIEventTypeMetaEndOfTrack,
    MIKMIDIEventTypeMetaTempoSetting,
    MIKMIDIEventTypeMetaSMPTEOffset,
    MIKMIDIEventTypeMetaTimeSignature,
    MIKMIDIEventTypeMetaKeySignature,
    MIKMIDIEventTypeMetaSequenceSpecificEvent
};

typedef NS_ENUM(NSUInteger, MIKMIDIMetaEventTypeType)
{
    MIKMIDIMetaEventTypeSequenceNumber          = 0x00,
    MIKMIDIMetaEventTypeTextEvent               = 0x01,
    MIKMIDIMetaEventTypeCopyrightNotice         = 0x02,
    MIKMIDIMetaEventTypeTrackSequenceName       = 0x03,
    MIKMIDIMetaEventTypeInstrumentName          = 0x04,
    MIKMIDIMetaEventTypeLyricText               = 0x05,
    MIKMIDIMetaEventTypeMarkerText              = 0x06,
    MIKMIDIMetaEventTypeCuePoint                = 0x07,
    MIKMIDIMetaEventTypeMIDIChannelPrefix       = 0x20,
    MIKMIDIMetaEventTypeEndOfTrack              = 0x2F,
    MIKMIDIMetaEventTypeTempoSetting            = 0x51,
    MIKMIDIMetaEventTypeSMPTEOffset             = 0x54,
    MIKMIDIMetaEventTypeTimeSignature           = 0x58,
    MIKMIDIMetaEventTypeKeySignature            = 0x59,
    MIKMIDIMetaEventTypeSequencerSpecificEvent  = 0x7F
};

@interface MIKMIDIEvent : NSObject <NSCopying>

@property (nonatomic, readonly) MusicEventType eventType;
@property (nonatomic, readonly) UInt8 channel;
@property (nonatomic, readonly) MusicTimeStamp timeStamp;
@property (nonatomic, readonly) NSData *data;

+ (instancetype)midiEventWithTimeStamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data;

@end

@interface MIKMutableMIDIEvent : MIKMIDIEvent

@property (nonatomic, readonly) MusicEventType eventType;
@property (nonatomic) MusicTimeStamp timeStamp;
@property (nonatomic, strong, readwrite) NSMutableData *data;

@end