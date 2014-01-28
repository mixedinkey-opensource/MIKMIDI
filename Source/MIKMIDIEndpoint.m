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

#if !__has_feature(objc_arc)
#error MIKMIDIEndpoint.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIEndpoint.m in the Build Phases for this target
#endif

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
		MIKMIDIEndpoint *source = [MIKMIDIEndpoint MIDIObjectWithObjectRef:sourceRef];
		if (!source) continue;
		[sources addObject:source];
	}
	return sources;
}

+ (NSArray *)virtualDestinationEndpoints
{
	NSMutableArray *destinations = [NSMutableArray array];
	ItemCount numDestinations = MIDIGetNumberOfDestinations();
	for (ItemCount i=0; i<numDestinations; i++) {
		MIDIEndpointRef destinationRef = MIDIGetDestination(i);
		MIKMIDIEndpoint *destination = [MIKMIDIEndpoint MIDIObjectWithObjectRef:destinationRef];
		if (!destination) continue;
		[destinations addObject:destination];
	}
	return destinations;
}

// Should always be MIKMIDISourceEndpoint or MIKMIDIDestinationEndpoint

- (BOOL)isPrivate
{
	NSError *error = nil;
	SInt32 result = MIKIntegerPropertyFromMIDIObject(self.objectRef, kMIDIPropertyPrivate, &error);
	if (result == INT32_MIN) {
		NSLog(@"Error getting private status for MIDI endpoint %@: %@", self, error);
		return NO;
	}
	return (result != 0);
}

@end
