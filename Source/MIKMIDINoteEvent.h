//
//  MIKMIDIEventMIDINoteMessage.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

/**
 *  A MIDI note event.
 */
@interface MIKMIDINoteEvent : MIKMIDIEvent

/**
 *  The MIDI note number for the event.
 */
@property (nonatomic, readonly) UInt8 note;

/**
 *  The initial velocity of the event.
 */
@property (nonatomic, readonly) UInt8 velocity;

/**
 *  The release velocity of the event. Use 0 if you don’t want to specify a particular value.
 */
@property (nonatomic, readonly) UInt8 releaseVelocity;

/**
 *  The duration of the event.
 */
@property (nonatomic, readonly) Float32 duration;

/**
 *  The time stamp at the end of the notes duration.
 */
@property (nonatomic, readonly) MusicTimeStamp endTimeStamp;

/**
 *  The frequency of the MIDI note. Based on an equal tempered scale with a 440Hz A5.
 */
@property (nonatomic, readonly) float frequency;

/**
 *  The note letter of the MIDI note. Notes that correspond to a "black key" on the piano will always be presented as sharp.
 */
@property (nonatomic, readonly) NSString *noteLetter;

/**
 *  The note letter and octave of the MIDI note. 0 is considered to be the first octave, so the note C0 is equal to MIDI note 0.
 */
@property (nonatomic, readonly) NSString *noteLetterAndOctave;

/**
 *  Convenience method for creating a new MIKMIDINoteEvent.
 *
 *  @param timeStamp The MusicTimeStamp for the event.
 *
 *  @param message The MIDINoteMessage for the event.
 *
 *  @return A new MIKMIDINoteEvent instance, or nil if there is an error.
 */
+ (instancetype)noteEventWithTimeStamp:(MusicTimeStamp)timeStamp message:(MIDINoteMessage)message;

@end

/**
 *  The mutable counterpart of MIKMIDINoteEvent
 */
@interface MIKMutableMIDINoteEvent : MIKMIDINoteEvent

@property (nonatomic, readwrite) UInt8 note;
@property (nonatomic, readwrite) UInt8 velocity;
@property (nonatomic, readwrite) UInt8 releaseVelocity;
@property (nonatomic, readwrite) Float32 duration;

@end