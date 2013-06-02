//
//  MIKMIDIObject_SubclassMethods.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIObject.h"

@interface MIKMIDIObject ()

+ (void)registerSubclass:(Class)subclass;
+ (NSArray *)representedMIDIObjectTypes;

@end
