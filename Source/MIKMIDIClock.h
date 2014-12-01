//
//  MIKMIDIClock.h
//  MIKMIDI
//
//  Created by Chris Flesner on 11/26/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@interface MIKMIDIClock : NSObject

+ (instancetype)clock;

- (void)setMusicTimeStamp:(MusicTimeStamp)musicTimeStamp withTempo:(Float64)tempo atMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;

- (MusicTimeStamp)musicTimeStampForMIDITimeStamp:(MIDITimeStamp)midiTimeStamp;
- (MIDITimeStamp)midiTimeStampForMusicTimeStamp:(MusicTimeStamp)musicTimeStamp;

+ (Float64)midiTimeStampsPerTimeInterval:(NSTimeInterval)timeInterval;

@end


#define MIKMIDIGetCurrentTimeStamp()	(mach_absolute_time())
