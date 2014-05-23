//
//  MIKMIDIEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"


static NSMutableSet *registeredMIKMIDIEventSubclasses;

@implementation MIKMIDIEvent

+ (void)registerSubclass:(Class)subclass;
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		registeredMIKMIDIEventSubclasses = [[NSMutableSet alloc] init];
	});
	[registeredMIKMIDIEventSubclasses addObject:subclass];
}

+ (BOOL)isMutable { return NO; }

+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return NO; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIEvent class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIEvent class]; }

+ (instancetype)midiEventWithTimestamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data
{
    Class subclass = [[self class] subclassForEventType:eventType andData:data];
	if (!subclass) subclass = self;
	if ([self isMutable]) subclass = [subclass mutableCounterpartClass];
	MIKMIDIEvent *result = [[subclass alloc] initWithTimeStamp:timeStamp eventType:eventType data:data];
    return result;
}

- (id)init
{
    self = [self initWithTimeStamp:0 eventType:MIKMIDIEventType_NULL data:nil];
    if (self) {
        self.internalData = [NSMutableData data];
    }
    return self;
}

- (id)initWithTimeStamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data
{
	self = [super init];
	if (self) {
		_musicTimeStamp = timeStamp;
		_eventType = eventType;
        self.internalData = [data mutableCopy];
	}
	return self;
}

- (NSString *)additionalEventDescription
{
    return @"";
}

- (NSString *)description
{
    NSString *additionalDescription = [self additionalEventDescription];
    if ([additionalDescription length] > 0) {
        additionalDescription = [NSString stringWithFormat:@"%@ ", additionalDescription];
    }
    return [NSString stringWithFormat:@"%@ Timestamp: %f Type: %u, %@", [super description], self.musicTimeStamp, (unsigned int)self.eventType, additionalDescription];
}

#pragma mark - Private

+ (MIKMIDIEventType)mikEventTypeForMusicEventType:(MusicEventType)musicEventType andData:(NSData *)data
{
    MIKMIDIEventType returnEventType = MIKMIDIEventType_NULL;
    if (musicEventType == kMusicEventType_Meta) {
        UInt8 metaEventType = (UInt8)[[data subdataWithRange:NSMakeRange(0, 1)] bytes];

        switch (metaEventType) {
            case MIKMIDIMetaEventCopyrightNotice:
                returnEventType = MIKMIDIEventType_MetaCopyright;
                break;
            
            case MIKMIDIMetaEventCuePoint:
                returnEventType = MIKMIDIEventType_MetaCuePoint;
                break;
                
            case MIKMIDIMetaEventEndOfTrack:
                returnEventType = MIKMIDIEventType_MetaEndOfTrack;
                break;
                
            case MIKMIDIMetaEventInstrumentName:
                returnEventType = MIKMIDIEventType_MetaInstrumentName;
                break;
                
            case MIKMIDIMetaEventKeySignature:
                returnEventType = MIKMIDIEventType_MetaKeySignature;
                break;
                
            case MIKMIDIMetaEventLyricText:
                returnEventType = MIKMIDIEventType_MetaLyricText;
                break;
                
            case MIKMIDIMetaEventMarkerText:
                returnEventType = MIKMIDIEventType_MetaMarkerText;
                break;
                
            case MIKMIDIMetaEventMIDIChannelPrefix:
                returnEventType = MIKMIDIEventType_MetaMIDIChannelPrefix;
                break;
                
            case MIKMIDIMetaEventSequenceNumber:
                returnEventType = MIKMIDIEventType_MetaSequence;
                break;
                
            case MIKMIDIMetaEventSequencerSpecificEvent:
                returnEventType = MIKMIDIEventType_MetaSequenceSpecificEvent;
                break;
                
            case MIKMIDIMetaEventSMPTEOffset:
                returnEventType = MIKMIDIEventType_MetaSMPTEOffset;
                break;
                
            case MIKMIDIMetaEventTempoSetting:
                returnEventType = MIKMIDIEventType_MetaTempoSetting;
                break;
                
            case MIKMIDIMetaEventTextEvent:
                returnEventType = MIKMIDIEventType_MetaText;
                break;
                
            case MIKMIDIMetaEventTimeSignature:
                returnEventType = MIKMIDIEventType_MetaTimeSignature;
                break;
                
            case MIKMIDIMetaEventTrackSequenceName:
                returnEventType = MIKMIDIEventType_MetaTrackSequenceName;
                break;
                
            default:
                returnEventType = MIKMIDIEventType_Meta;
                break;
        }
    } else {
        switch (musicEventType) {
            case kMusicEventType_AUPreset:
                returnEventType = MIKMIDIEventType_AUPreset;
                break;
                
            case kMusicEventType_ExtendedNote:
                returnEventType = MIKMIDIEventType_ExtendedNote;
                break;
            case kMusicEventType_ExtendedTempo:
                returnEventType = MIKMIDIEventType_ExtendedTempo;
                break;
            case kMusicEventType_MIDIChannelMessage:
                returnEventType = MIKMIDIEventType_MIDIChannelMessage;
                break;
            case kMusicEventType_MIDINoteMessage:
                returnEventType = MIKMIDIEventType_MIDINoteMessage;
                break;
            case kMusicEventType_MIDIRawData:
                returnEventType = MIKMIDIEventType_MIDIRawData;
                break;
            case kMusicEventType_Parameter:
                returnEventType = MIKMIDIEventType_Parameter;
                break;
            case kMusicEventType_User:
                returnEventType = MIKMIDIEventType_User;
                break;
            case kMusicEventType_ExtendedControl:
                returnEventType = MIKMIDIEventType_ExtendedControl;
                break;
            default:
                returnEventType = MIKMIDIEventType_NULL;
                break;
        }
    }
    
    return returnEventType;
}

+ (Class)subclassForEventType:(MusicEventType)eventType andData:(NSData *)data
{
	Class result = nil;
    MIKMIDIEventType midiEventType = [[self class] mikEventTypeForMusicEventType:eventType andData:data];
	for (Class subclass in registeredMIKMIDIEventSubclasses) {
		if ([subclass supportsMIKMIDIEventType:midiEventType]) {
			result = subclass;
			break;
		}
    }
	return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	Class copyClass = [[self class] immutableCounterpartClass];
	MIKMIDIEvent *result = [[copyClass alloc] init];
	result.internalData = self.internalData;
	result.eventType = self.eventType;
	result.musicTimeStamp = self.musicTimeStamp;
	return result;
}

- (id)mutableCopy
{
	Class copyClass = [[self class] mutableCounterpartClass];
	MIKMutableMIDIEvent *result = [[copyClass alloc] init];
	result.internalData = self.internalData;
	result.eventType = self.eventType;
	result.musicTimeStamp = self.musicTimeStamp;
	return result;
}

- (NSData *)data { return [self.internalData copy]; }

- (void)setData:(NSData *)data
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	self.internalData = [data mutableCopy];
}

@end

@implementation MIKMutableMIDIEvent

+ (BOOL)isMutable { return YES; }

+ (BOOL)supportsMIKMIDIEventType:(MIKMIDIEventType)type { return [[self immutableCounterpartClass] supportsMIKMIDIEventType:type]; }

@dynamic eventType;
@dynamic channel;
@dynamic data;

@end