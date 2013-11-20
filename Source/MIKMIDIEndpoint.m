//
//  MIKMIDIEndpoint.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEndpoint.h"
#import "MIKMIDIUtilities.h"
#import "MIKMIDIEntity.h"

@interface MIKMIDIEndpoint ()

@property (nonatomic, weak, readwrite) MIKMIDIEntity *entity;

@end

@implementation MIKMIDIEndpoint

+ (NSArray *)virtualSourceEndpoints
{
	NSMutableArray *sources = [NSMutableArray array];
	ItemCount numSources = MIDIGetNumberOfSources();
	for (ItemCount i=0; i<numSources; i++) {
		MIDIEndpointRef sourceRef = MIDIGetSource(i);
		MIKMIDISourceEndpoint *source = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:sourceRef];
		if (!source) continue;
		[sources addObject:source];
	}
	self.internalVirtualSources = sources;
}

+ (NSArray *)virtualDestinationEndpoints
{
	NSMutableArray *destinations = [NSMutableArray array];
	ItemCount numDestinations = MIDIGetNumberOfDestinations();
	for (ItemCount i=0; i<numDestinations; i++) {
		MIDIEndpointRef destinationRef = MIDIGetDestination(i);
		MIKMIDISourceEndpoint *destination = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:destinationRef];
		if (!destination) continue;
		[destinations addObject:destination];
	}
	self.internalVirtualDestinations = destinations;
}

// Abstract. Should always be MIKMIDISourceEndpoint or MIKMIDIDestinationEndpoint

@end
