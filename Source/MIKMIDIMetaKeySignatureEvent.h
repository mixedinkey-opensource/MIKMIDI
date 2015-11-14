//
//  MIKMIDIMetaKeySignatureEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"
#import "MIKMIDICompilerCompatibility.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A meta event containing key signature information.
 */
@interface MIKMIDIMetaKeySignatureEvent : MIKMIDIMetaEvent

/**
 *  The key for the event. Values can be between -7 and 7 and specify
 *  the key signature in terms of number of flats (if negative) or sharps (if positive).
 */
@property (nonatomic, readonly) UInt8 key;

/**
 *  The scale for the event. A value of 0 indicates a major scale, a value of 1 indicates a minor scale.
 */
@property (nonatomic, readonly) UInt8 scale;

@end

/**
 *  The mutable counterpart of MIKMIDIMetaKeySignatureEvent.
 */
@interface MIKMutableMIDIMetaKeySignatureEvent : MIKMIDIMetaKeySignatureEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite, null_resettable) NSData *metaData;
@property (nonatomic, readwrite) UInt8 key;
@property (nonatomic, readwrite) UInt8 scale;

@end

NS_ASSUME_NONNULL_END