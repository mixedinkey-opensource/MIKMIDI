//
//  MIKMIDISourceEndpoint.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISourceEndpoint.h"
#import "MIKMIDIObject_SubclassMethods.h"

@implementation MIKMIDISourceEndpoint

+(void)load { [MIKMIDIObject registerSubclass:[self class]]; }

+ (NSArray *)representedMIDIObjectTypes; { return @[@(kMIDIObjectType_Source)]; }

@end
