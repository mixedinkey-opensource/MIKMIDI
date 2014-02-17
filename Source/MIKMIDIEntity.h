//
//  MIKMIDIEntity.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIObject.h"

@class MIKMIDIDevice;

/**
 *  MIKMIDIEntity represents a logical grouping of endpoints within a MIDI device. It essentially
 *  acts as a simple container for endpoints.
 *
 *  As part of MIKMIDIDevice's support for wrapping virtual endpoints, an MIKMIDIEntity can also
 *  be created using virtual MIDI endpoints.
 */
@interface MIKMIDIEntity : MIKMIDIObject

/**
 *  Convenience method for creating a "virtual" MIKMIDIEntity instance from one or more virtual endpoints.
 *  This method is typically not called directly by clients of MIKMIDI. Rather it's used by MIKMIDIDevice's
 *  internal machinery for creating virtual devices.
 *
 *  @param endpoints An array of one or more virtual endpoints, including both source and destination endpoints.
 *
 *  @return An initialized MIKMIDIEntity instance.
 *
 *  @see +[MIKMIDIDevice deviceWithVirtualEndpoints:]
 */
+ (instancetype)entityWithVirtualEndpoints:(NSArray *)endpoints;

/**
 *  Creates and initializes a "virtual" MIKMIDIEntity instance from one or more virtual endpoints.
 *  This method is typically not called directly by clients of MIKMIDI. Rather it's used by MIKMIDIDevice's
 *  internal machinery for creating virtual devices.
 *
 *  @param endpoints An array of one or more virtual endpoints, including both source and destination endpoints.
 *
 *  @return An initialized MIKMIDIEntity instance.
 *
 *  @see -[MIKMIDIDevice initWithVirtualEndpoints:]
 */
- (instancetype)initWithVirtualEndpoints:(NSArray *)endpoints;

/**
 *  The device that contains the receiver. May be nil if the receiver is a virtual entity not contained
 *  by a virtual device.
 */
@property (nonatomic, weak, readonly) MIKMIDIDevice *device;

/**
 *  The source (input) endpoints contained by the receiver. 
 *  An array of MIKMIDISourceEndpoint instances.
 */
@property (nonatomic, readonly) NSArray *sources;

/**
 *  The destination (output) endpoints contained by the receiver. 
 *  An array of MIKMIDIDestinationEndpoint instances.
 */
@property (nonatomic, readonly) NSArray *destinations;

@end
