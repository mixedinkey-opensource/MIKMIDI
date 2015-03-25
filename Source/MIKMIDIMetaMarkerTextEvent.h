//
//  MIKMIDIMetaMarkerTextEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTextEvent.h"

/**
 *  A meta event containing marker information.
 */
@interface MIKMIDIMetaMarkerTextEvent : MIKMIDIMetaTextEvent

@end

/**
 *  The mutable counterpart of MIKMIDIMetaMarkerTextEvent.
 */
@interface MIKMutableMIDIMetaMarkerTextEvent : MIKMIDIMetaMarkerTextEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite) NSData *metaData;

@end