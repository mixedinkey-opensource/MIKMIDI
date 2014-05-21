//
//  MIKMIDITrack.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDITrack.h"


@implementation MIKMIDITrack
{
	MusicTrack *_musicTrack;
}

- (instancetype)initWithMusicTrack:(MusicTrack *)musicTrack;
{
	self = [super init];
	if (self) {
		_musicTrack = musicTrack;
	}
	return self;
}

- (void)cleanup
{
	_musicTrack = NULL;
}

@end
