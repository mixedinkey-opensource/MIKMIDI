//
//  MIKMIDISynthesizerInstrument.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/19/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

/**
 *  MIKMIDISynthesizerInstrument is used to represent
 */
@interface MIKMIDISynthesizerInstrument : NSObject

/**
 *  Creates and initializes an MIKMIDISynthesizerInstrument with the corresponding instrument ID.
 *
 *  @param instrumentID The MusicDeviceInstrumentID for the desired MIKMIDISynthesizerInstrument
 *  @param name         The human readable name of the instrument. 
 *
 *  @return A MIKMIDISynthesizerInstrument instance with the matching instrument ID, or nil if no instrument was found.
 */
+ (instancetype)instrumentWithID:(MusicDeviceInstrumentID)instrumentID name:(NSString *)name;

/**
 *  The human readable name of the receiver. e.g. "Piano 1".
 */
@property (nonatomic, copy, readonly) NSString *name;

/**
 *  The Core Audio supplied instrumentID for the receiver.
 */
@property (nonatomic, readonly) MusicDeviceInstrumentID instrumentID;

@end

// For backwards compatibility with applications written against MIKMIDI 1.0.x
@compatibility_alias MIKMIDIEndpointSynthesizerInstrument MIKMIDISynthesizerInstrument;

@interface MIKMIDISynthesizerInstrument (Deprecated)

/**
 *	@deprecated Use -[MIKMIDISynthesizer availableInstruments] instead.
 *
 *  An array of available MIKMIDISynthesizerInstruments for use
 *  with MIKMIDIEndpointSynthesizer.
 *
 *  @return An NSArray containing MIKMIDISynthesizerInstrument instances.
 */
+ (NSArray *)availableInstruments DEPRECATED_ATTRIBUTE;

/**
 *	@deprecated Use +instrumentWithID:inInstrumentUnit: instead.
 *
 *  Creates and initializes an MIKMIDISynthesizerInstrument with the corresponding instrument ID.
 *
 *  @param instrumentID The MusicDeviceInstrumentID for the desired MIKMIDISynthesizerInstrument
 *
 *  @return A MIKMIDISynthesizerInstrument with the matching instrument ID, or nil if no instrument was found.
 */
+ (instancetype)instrumentWithID:(MusicDeviceInstrumentID)instrumentID DEPRECATED_ATTRIBUTE;

@end