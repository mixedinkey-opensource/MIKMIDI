//
//  MIKMIDIMetronome.m
//  MIKMIDI
//
//  Created by Chris Flesner on 11/24/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetronome.h"
#import "MIKMIDINoteEvent.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMetronome.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@implementation MIKMIDIMetronome

- (void)setupMetronome
{
	self.tickMessage = (MIDINoteMessage){ .channel = 0, .note = 57, .velocity = 127, .duration = 0.5, .releaseVelocity = 0 };
	self.tockMessage = (MIDINoteMessage){ .channel = 0, .note = 56, .velocity = 127, .duration = 0.5, .releaseVelocity = 0 };
	[self selectInstrument:[MIKMIDIEndpointSynthesizerInstrument instrumentWithID:7864376]];
}

- (instancetype)init
{
	if (self = [super init]) {
		[self setupMetronome];
	}
	return self;
}

- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination componentDescription:(AudioComponentDescription)componentDescription
{
	if (self = [super initWithClientDestinationEndpoint:destination componentDescription:componentDescription]) {
		[self setupMetronome];
	}
	return self;
}

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source componentDescription:(AudioComponentDescription)componentDescription
{
	if (self = [super initWithMIDISource:source componentDescription:componentDescription]) {
		[self setupMetronome];
	}
	return self;
}

@end
