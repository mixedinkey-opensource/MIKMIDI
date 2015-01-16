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
 *  MIKMIDIClock is used to convert back and forth between MIDITimeStamp and MusicTimeStamp.
 *  It is not intended for use by clients/users of of MIKMIDI. Rather, it should be thought 
 *  of as an MIKMIDI private class.
 */
@interface MIKMIDIClock : NSObject <NSCopying>

+ (instancetype)clock;

- (void)setMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withTempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;
- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp;

+ (Float64)midiTimeStampsPerTimeInterval:(NSTimeInterval)timeInterval;

@end

