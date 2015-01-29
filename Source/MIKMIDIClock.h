//
//  MIKMIDIClock.h
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


/**
 *  MIKMIDIClock provides the number of seconds per MIDITimeStamp, as well as the
 *  number of MIDITimeStamps per a specified time interval.
 *
 *  Instances of MIKMIDIClock can also be used to convert between MIDITimeStamp
 *  and MusicTimeStamp.
 */
@interface MIKMIDIClock : NSObject <NSCopying>

/**
 *  Returns the number of MIDITimeStamps that would occur during a specified time interval.
 *
 *  @param timeInterval The number of seconds to convert into number of MIDITimeStamps.
 *
 *  @return The number of MIDITimeStamps that would occur in the specified time interval.
 */
+ (Float64)midiTimeStampsPerTimeInterval:(NSTimeInterval)timeInterval;

/**
 *  Returns the number of seconds per each MIDITimeStamp.
 *
 *  @return Then number of seconds per each MIDITimeStamp.
 */
+ (Float64)secondsPerMIDITimeStamp;

/**
 *  Creates and initializes a new instance of MIKMIDIClock.
 *
 *  @return A new instance of MIKMIDIClock.
 */
+ (instancetype)clock;

/**
 *  Internally synchronizes the musicTimeStamp with the midiTimeStamp using the specified tempo. 
 *  This method must be called at least once before -musicTimeStampForMIDITimeStamp: and 
 *  -midiTimeStampForMusicTimeStamp: will return any meaningful values.
 *
 *  @param musicTimeStamp The MusicTimeStamp to synchronize the clock to.
 *
 *  @param tempo The beats per minute at which MusicTimeStamps should tick.
 *
 *  @param midiTimeStamp The MIDITimeStamp to synchronize the clock to.
 *
 *  @see -musicTimeStampForMIDITimeStamp:
 *  @see -midiTimeStampForMusicTimeStamp:
 */
- (void)setMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withTempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

/**
 *  Converts the specified MIDITimeStamp into the corresponding MusicTimeStamp.
 *
 *  @param midiTimeStamp The MIDITimeStamp to convert into a MusicTimeStamp.
 *
 *  @return The MusicTimeStamp that will occur at the same time as the specified MIDITimeStamp.
 *
 *  @note For this method to return any meaningful values, you must first call
 *  -setMusicTimeStamp:withTempo:atMIDITimeStamp: at least once.
 *
 *  @see -setMusicTimeStamp:withTempo:atMIDITimeStamp:
 */
- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

/**
 *  Converts the specified MusicTimeStamp into the corresponding MIDITimeStamp.
 *
 *  @param musicTimeStamp The MusicTimeStamp to convert into a MIDITimeStamp.
 *
 *  @return The MIDITimeStamp that will occur at the same time as the specified MusicTimeStamp.
 *
 *  @note For this method to return any meaningful values, you must first call
 *  -setMusicTimeStamp:withTempo:atMIDITimeStamp: at least once.
 *
 *  @see -setMusicTimeStamp:withTempo:atMIDITimeStamp:
 */
- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp;

@end

