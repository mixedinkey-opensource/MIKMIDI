//
//  MIKMIDITrack+MIKMIDIPrivate.h
//  MIKMIDI
//
//  Created by Chris Flesner on 6/30/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDI.h>


@interface MIKMIDITrack (MIKMIDIPrivate)

@property (readonly, nonatomic) MusicTimeStamp private_length;

- (NSArray *)private_eventsOfClass:(Class)eventClass fromTimeStamp:(MusicTimeStamp)startTimeStamp toTimeStamp:(MusicTimeStamp)endTimeStamp;

@end
