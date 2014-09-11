//
//  MIKMIDITempoEvent.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

@interface MIKMIDITempoEvent : MIKMIDIEvent

@property (nonatomic, readonly) Float64 bpm;

+ (instancetype)tempoEvenWithTimeStamp:(MusicTimeStamp)timeStamp tempo:(Float64)bpm;

@end

@interface MIKMutableMIDITempoEvent : MIKMIDITempoEvent

@property (nonatomic, readwrite) Float64 bpm;

@end