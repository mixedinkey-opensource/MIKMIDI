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

@interface MIKMIDIOutputPort : MIKMIDIPort

- (BOOL)sendCommands:(NSArray *)commands toDestination:(MIKMIDIDestinationEndpoint *)destination error:(NSError **)error;

@end
