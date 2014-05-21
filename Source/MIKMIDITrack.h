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

- (instancetype)initWithMusicTrack:(MusicTrack *)musicTrack;

/**
 *  MIKMIDITrack can't own its track structure, so this is used by the
 *  owning sequence to tell it to get rid of its reference to it.
 */
- (void)cleanup;

@end
