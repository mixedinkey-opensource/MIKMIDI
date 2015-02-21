//
//  MIKMIDIDestinationEndpoint.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIDestinationEndpoint.h"
#import "MIKMIDIObject_SubclassMethods.h"

#if !__has_feature(objc_arc)
#error MIKMIDIDestinationEndpoint.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIDestinationEndpoint.m in the Build Phases for this target
#endif

@implementation MIKMIDIDestinationEndpoint

+ (void)load { [MIKMIDIObject registerSubclass:[self class]]; }

+ (NSArray *)representedMIDIObjectTypes; { return @[@(kMIDIObjectType_Destination)]; }

#pragma mark - Public

- (void)unscheduleAllPendingEvents
{
	MIDIFlushOutput(self.objectRef);
}

@end
