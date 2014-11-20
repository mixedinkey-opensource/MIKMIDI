//
//  MIKMIDIEventIterator.h
//  MIKMIDI
//
//  Created by Chris Flesner on 9/9/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MIKMIDITrack;
@class MIKMIDIEvent;

/**
 *  MIKMIDIEventIterator is an Objective-C wrapper for CoreMIDI's MusicEventIterator. It is not intended for use by clients/users of
 *  of MIKMIDI. Rather, it should be thought of as an MIKMIDI private class.
 */
@interface MIKMIDIEventIterator : NSObject

@property (nonatomic, readonly) BOOL hasPreviousEvent;
@property (nonatomic, readonly) BOOL hasCurrentEvent;
@property (nonatomic, readonly) BOOL hasNextEvent;
@property (nonatomic, readonly) MIKMIDIEvent *currentEvent;

- (instancetype)initWithTrack:(MIKMIDITrack *)track;
+ (instancetype)iteratorForTrack:(MIKMIDITrack *)track;

- (BOOL)seek:(MusicTimeStamp)timeStamp;
- (BOOL)moveToNextEvent;
- (BOOL)moveToPreviousEvent;

@end
