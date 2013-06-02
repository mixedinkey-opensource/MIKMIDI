//
//  MIKMIDIEntity.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIObject.h"

@class MIKMIDIDevice;

@interface MIKMIDIEntity : MIKMIDIObject

@property (nonatomic, weak, readonly) MIKMIDIDevice *device; // May be nil (e.g. for virtual endpoints)

@property (nonatomic, readonly) NSArray *sources;
@property (nonatomic, readonly) NSArray *destinations;

@end
