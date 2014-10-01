//
//  MIKMIDIEndpointSynthesizer.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 5/27/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MIKMIDIEndpoint;
@class MIKMIDISourceEndpoint;
@class MIKMIDIClientDestinationEndpoint;
@class MIKMIDIEndpointSynthesizerInstrument;

/**
 * MIKMIDIEndpointSynthesizer provides a very simple way to synthesize MIDI commands coming from a
 * source endpoint (e.g. from a connected MIDI piano keyboard) to produce sound output.
 *
 * To use it, simply create a synthesizer instance with the source you'd like it to play. It will
 * continue playing incoming MIDI until it is deallocated.
 */
@interface MIKMIDIEndpointSynthesizer : NSObject

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source;

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;


/**
 * Creates and returns an array of available MIKMIDIEndpointSynthesizerInstruments
 *
 * @return An array of MIKMIDIEndpointSynthesizerInstrument
 */
- (NSArray *)availableInstruments;

/**
 * Gets the instrument with the corresponding instrument ID.
 *
 * @param instrumentID The MusicDeviceInstrumentID for the desired MIKMIDIEndpointSynthesizerInstrument
 *
 * @return A MIKMIDIEndpointSynthesizerInstrument with the matching instrument ID, or nil if no instrument was found
 */
- (MIKMIDIEndpointSynthesizerInstrument *)instrumentForID:(MusicDeviceInstrumentID)instrumentID;

/**
 * Gets the instrument with the corresponding name.
 *
 * @param name The name of the desired MIKMIDIEndpointSynthesizerInstrument
 *
 * @return A MIKMIDIEndpointSynthesizerInstrument with the matching name, or nil if no instrument was found
 *
 * @discussion This method is implemented by calling -availableInstruments and looping through to find the instrument
 * with the matching name, and is thus somewhat expensive.
 */
- (MIKMIDIEndpointSynthesizerInstrument *)instrumentWithName:(NSString *)name; 

/**
 * Changes the instrument patch for a channel.
 *
 * @param instrument Any MIKMIDIEndpointSynthesizerInstrument from -availableInstruments.
 *
 * @param channel The MIDI channel you'd like to change the instrument patch for.
 *
 * @return YES if the instrument patch was successfully changed, NO if the change failed
 */
- (BOOL)selectInstrument:(MIKMIDIEndpointSynthesizerInstrument *)instrument forChannel:(UInt8)channel;


/**
 * Changes the instrument patch for a channel.
 *
 * @param instrumentID The MusicDeviceInstrumentID you'd like to change the instrument to to.
 *
 * @param channel The MIDI channel you'd like to change the instrument patch for.
 *
 * @return YES if the instrument patch was successfully changed, NO if the change failed
 */
- (BOOL)selectInstrumentWithID:(MusicDeviceInstrumentID)instrumentID forChannel:(UInt8)channel;

@property (nonatomic, strong, readonly) MIKMIDIEndpoint *endpoint;


- (void)handleMIDIMessages:(NSArray *)commands;

- (void)noteOn:(UInt8)note velocity:(UInt8)velocity channel:(UInt8)channel;
- (void)noteOff:(UInt8)note velocity:(UInt8)velocity channel:(UInt8)channel;
- (void)noteOff:(UInt8)note channel:(UInt8)channel; // same as noteOff:velocity:channel with a release velocity of 0

@end



@interface MIKMIDIEndpointSynthesizerInstrument : NSObject

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, nonatomic) MusicDeviceInstrumentID instrumentID;

+ (instancetype)instrumentWithName:(NSString *)name instrumentID:(MusicDeviceInstrumentID)instrumentID;

@end

#endif // !TARGET_OS_IPHONE