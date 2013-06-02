//
//  MIKMIDIDestinationEndpoint.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIDestinationEndpoint.h"
#import "MIKMIDIObject_SubclassMethods.h"

@implementation MIKMIDIDestinationEndpoint

+(void)load { [MIKMIDIObject registerSubclass:[self class]]; }

+ (NSArray *)representedMIDIObjectTypes; { return @[@(kMIDIObjectType_Destination)]; }

@end
