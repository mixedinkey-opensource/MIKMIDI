//
//  MIKMIDITrack.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MIKMIDITrack : NSObject

- (instancetype)initWithMusicTrack:(MusicTrack)musicTrack;

@property (nonatomic, readonly) BOOL doesLoop;
@property (nonatomic, readonly) NSInteger numberOfLoops; // 0 means loops forever
@property (nonatomic, readonly) MusicTimeStamp loopDuration;

@property (nonatomic, readonly, getter = isMuted) BOOL muted;
@property (nonatomic, readonly, getter = isSolo) BOOL solo;

@property (nonatomic, readonly) MusicTimeStamp length;
@property (nonatomic, readonly, copy) NSArray *events;

@end
