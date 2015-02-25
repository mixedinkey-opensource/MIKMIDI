//
//  MIKMIDITrack_Protected.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/25/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDITrack.h"

@interface MIKMIDITrack ()

/**
 *  Creates and initializes a new MIKMIDITrack.
 *
 *  @param sequence The MIDI sequence the new track will belong to.
 *  @param musicTrack The MusicTrack to use as the backing for the new MIDI track.
 *
 *  @note You should not call this method. It is for internal MIKMIDI use only.
 *  To add a new track to a MIDI sequence use -[MIKMIDISequence addTrack].
 */
+ (instancetype)trackWithSequence:(MIKMIDISequence *)sequence musicTrack:(MusicTrack)musicTrack;

@end
