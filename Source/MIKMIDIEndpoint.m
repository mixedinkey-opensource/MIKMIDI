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

// Abstract. Should always be MIKMIDISourceEndpoint or MIKMIDIDestinationEndpoint

@end
