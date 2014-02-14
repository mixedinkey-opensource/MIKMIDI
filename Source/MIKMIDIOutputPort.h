//
//  MIKMIDIOutputPort.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPort.h"

@class MIKMIDICommand;
@class MIKMIDIDestinationEndpoint;

/**
 *  MIKMIDIInputPort is an Objective-C wrapper for CoreMIDI's MIDIPort class, and is only for destination ports.
 *  It is not intended for use by clients/users of of MIKMIDI. Rather, it should be thought of as an
 *  MIKMIDI private class.
 */
@interface MIKMIDIOutputPort : MIKMIDIPort

- (BOOL)sendCommands:(NSArray *)commands toDestination:(MIKMIDIDestinationEndpoint *)destination error:(NSError **)error;

@end
