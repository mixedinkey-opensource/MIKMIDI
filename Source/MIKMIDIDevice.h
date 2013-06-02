//
//  MIKMIDIDevice.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import "MIKMIDIObject.h"

@interface MIKMIDIDevice : MIKMIDIObject

@property (nonatomic, strong, readonly) NSString *manufacturer;
@property (nonatomic, strong, readonly) NSString *model;

@property (nonatomic, strong, readonly) NSArray *entities;

@end
