//
//  MIKMIDIProgramChangeEvent.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 3/4/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelEvent.h"

/**
 *  A MIDI program change event.
 *
 *  Program change events indicate a change in the patch number.
 *  These events can be sent to to a MIDI device or synthesizer to
 *	change the instrument the instrument/voice being used to synthesize MIDI.
 *
 *  This event is the counterpart to MIKMIDIProgramChangeCommand in the context
 *  of sequences/MIDI Files.
 */
@interface MIKMIDIProgramChangeEvent : MIKMIDIChannelEvent

/**
 *  The program (aka patch) number. From 0-127.
 */
@property (nonatomic, readonly) NSUInteger programNumber;

@end

/**
 *  The mutable counter part of MIKMIDIProgramChangeEvent
 */
@interface MIKMutableMIDIProgramChangeEvent : MIKMIDIProgramChangeEvent

@property (nonatomic, readwrite) NSUInteger programNumber;

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, strong, readwrite) NSMutableData *data;
@property (nonatomic, readwrite) UInt8 channel;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@end
