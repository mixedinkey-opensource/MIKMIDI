//
//  MIKMIDITimeSignatureEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"
#import "MIKMIDICompilerCompatibility.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  A meta event containing time signature information.
 */
@interface MIKMIDIMetaTimeSignatureEvent : MIKMIDIMetaEvent

/**
 *  The numerator of the time signature.
 */
@property (nonatomic, readonly) UInt8 numerator;

/**
 *  The denominator of the time signature.
 */
@property (nonatomic, readonly) UInt8 denominator;

/**
 *  The number of MIDI clock ticks per metronome tick.
 */
@property (nonatomic, readonly) UInt8 metronomePulse;

/**
 *  The number of notated 32nd notes in a MIDI quarter note.
 */
@property (nonatomic, readonly) UInt8 thirtySecondsPerQuarterNote;

@end

/**
 *  The mutable counterpart of MIKMIDIMetaTimeSignatureEvent.
 */
@interface MIKMutableMIDIMetaTimeSignatureEvent : MIKMIDIMetaTimeSignatureEvent

@property (nonatomic, readwrite) UInt8 metadataType;
@property (nonatomic, strong, readwrite, null_resettable) NSData *metaData;
@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) UInt8 numerator;
@property (nonatomic, readwrite) UInt8 denominator;
@property (nonatomic, readwrite) UInt8 metronomePulse;
@property (nonatomic, readwrite) UInt8 thirtySecondsPerQuarterNote;

@end

NS_ASSUME_NONNULL_END