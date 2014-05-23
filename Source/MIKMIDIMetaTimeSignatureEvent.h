//
//  MIKMIDITimeSignatureEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"

@interface MIKMIDIMetaTimeSignatureEvent : MIKMIDIMetaEvent

@property (nonatomic, readonly) UInt8 numerator;
@property (nonatomic, readonly) UInt8 denominator;
@property (nonatomic, readonly) UInt8 metronomePulse;
@property (nonatomic, readonly) UInt8 thirtySecondsPerQuarterNote;

@end

@interface MIKMutableMIDIMetaTimeSignatureEvent : MIKMIDIMetaTimeSignatureEvent

@property (nonatomic, readwrite) UInt8 numerator;
@property (nonatomic, readwrite) UInt8 denominator;
@property (nonatomic, readwrite) UInt8 metronomePulse;
@property (nonatomic, readwrite) UInt8 thirtySecondsPerQuarterNote;

@end