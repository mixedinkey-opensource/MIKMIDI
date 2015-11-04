//
//  MIKMIDIMetadataTextEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"

/**
 *  A meta event containing text.
 */
@interface MIKMIDIMetaTextEvent : MIKMIDIMetaEvent

/**
 *  The text for the event.
 */
@property (nonatomic, readonly) NSString *string;

@end

/**
 *  The mutable counterpart of MIKMIDIMetaTextEvent.
 */
@interface MIKMutableMIDIMetaTextEvent : MIKMIDIMetaTextEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite) NSData *metaData;
@property (nonatomic, copy, readwrite) NSString *string;

@end