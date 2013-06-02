//
//  MIKMIDIPort.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPort.h"
#import "MIKMIDIEndpoint.h"
#import "MIKMIDIPort_SubclassMethods.h"

@implementation MIKMIDIPort

- (id)initWithClient:(MIDIClientRef)clientRef name:(NSString *)name
{
	self = [super init];
	if (self) {
		
	}
	return self;
}

- (void)dealloc
{
	if (_portRef) MIDIPortDispose(_portRef);
}

#pragma mark - Properties

- (void)setPortRef:(MIDIPortRef)portRef
{
	if (portRef != _portRef) {
		if (_portRef) MIDIPortDispose(_portRef);
		_portRef = portRef;
	}
}

@end
