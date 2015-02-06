//
//  MIKMIDIEndpointSynthesizer.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 5/27/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@class MIKMIDIEndpoint;
@class MIKMIDISourceEndpoint;
@class MIKMIDIClientDestinationEndpoint;
@class MIKMIDIEndpointSynthesizerInstrument;

/**
 *  MIKMIDIEndpointSynthesizer provides a very simple way to synthesize MIDI commands coming from a
 *  source endpoint (e.g. from a connected MIDI piano keyboard) to produce sound output.
 *
 *  To use it, simply create a synthesizer instance with the source you'd like it to play. It will
 *  continue playing incoming MIDI until it is deallocated.
 */
@interface MIKMIDIEndpointSynthesizer : NSObject

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance using Apple's DLS synth as the
 *  underlying instrument.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source;

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @param componentDescription an AudioComponentDescription describing the Audio Unit instrument
 *  you would like the synthesizer to use.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source componentDescription:(AudioComponentDescription)componentDescription;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance using Apple's DLS synth as the
 *  underlying instrument.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param source An MIKMIDISourceEndpoint instance from which MIDI note events will be received.
 *
 *  @param componentDescription an AudioComponentDescription describing the Audio Unit instrument
 *  you would like the synthesizer to use.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source componentDescription:(AudioComponentDescription)componentDescription;

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance using Apple's DLS synth as the
 *  underlying instrument.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @param componentDescription an AudioComponentDescription describing the Audio Unit instrument
 *  you would like the synthesizer to use.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination componentDescription:(AudioComponentDescription)componentDescription;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance using Apple's DLS synth as the
 *  underlying instrument.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;

/**
 *  Initializes an MIKMIDIEndpointSynthesizer instance.
 *
 *  @param destination An MIKMIDIClientDestinationEndpoint instance from which MIDI note events will be received.
 *
 *  @param componentDescription an AudioComponentDescription describing the Audio Unit instrument
 *  you would like the synthesizer to use.
 *
 *  @return An initialized MIKMIDIEndpointSynthesizer or nil if an error occurs.
 */
- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination componentDescription:(AudioComponentDescription)componentDescription;

/**
 * Changes the instrument/voice used by the synthesizer.
 *
 *  @param instrument An MIKMIDIEndpointSynthesizerInstrument instance.
 *
 *  @return YES if the instrument was successfully changed, NO if the change failed.
 *
 *  @see +[MIKMIDIEndpointSynthesizerInstrument availableInstruments]
 */
- (BOOL)selectInstrument:(MIKMIDIEndpointSynthesizerInstrument *)instrument;

/**
 *  Plays MIDI messages through the synthesizer.
 *
 *  This method can be used to synthesize arbitrary MIDI events. It is especially
 *  useful for MIKMIDIEndpointSynthesizers that are not connected to a MIDI
 *  endpoint.
 *
 *  @param messages An NSArray of MIKMIDICommand (subclass) instances.
 */
- (void)handleMIDIMessages:(NSArray *)messages;

/**
 *  The endpoint from which the receiver is receiving MIDI messages.
 *  This may be either an external MIKMIDISourceEndpoint, e.g. to synthesize MIDI
 *  events coming from an external MIDI keyboard, or it may be an MIKMIDIClientDestinationEndpoint,
 *  most commonly to synthesize MIDI coming from an MIKMIDIPlayer.
 *
 */
@property (nonatomic, strong, readonly) MIKMIDIEndpoint *endpoint;

/**
 *  The component description of the underlying Audio Unit instrument.
 */
@property (nonatomic, readonly) AudioComponentDescription componentDescription;

/**
 *  The Audio Unit instrument that ultimately receives all of the MIDI messages sent to
 *  this endpoint synthesizer.
 *
 *  @note You should only use the setter for this property from an
 *  MIKMIDIEndpointSynthesizer subclass.
 *
 *  @see -setupAUGraph
 */
@property (nonatomic) AudioUnit instrument;


/**
 *  The AUGraph for the instrument.
 *
 *  @note You should only use the setter for this property from an 
 *  MIKMIDIEndpointSynthesizer subclass.
 *
 *  @see -setupAUGraph
 */
@property (nonatomic) AUGraph graph;

/**
 *  Sets up the AUGraph for the instrument. Do not call this method, as it is 
 *  called automatically during initialization.
 *  
 *  The method is provided to give subclasses a chance to override
 *  the AUGraph behavior for the instrument. If you do override it, you will need
 *  to create an AudioUnit instrument and set it to the instrument property. Also,
 *  if you intend to use the graph property, you will be responsible for setting
 *  that as well. DisposeAUGraph() is called on the previous graph when setting 
 *  the graph property, and in dealloc.
 *
 *  @return YES is setting up the graph was succesful, and initialization
 *  should continue, NO if setting up the graph failed and initialization should
 *  return nil.
 */
- (BOOL)setupAUGraph;

@end

#pragma mark -

/**
 *  MIKMIDIEndpointSynthesizerInstrument is used to represent
 */
@interface MIKMIDIEndpointSynthesizerInstrument : NSObject

/**
 *  An array of available MIKMIDIEndpointSynthesizerInstruments for use
 *  with MIKMIDIEndpointSynthesizer.
 *
 *  @return An NSArray containing MIKMIDIEndpointSynthesizerInstrument instances.
 */
+ (NSArray *)availableInstruments;

/**
 *  Creates and initializes an MIKMIDIEndpointSynthesizerInstrument with the corresponding instrument ID.
 *
 *  @param instrumentID The MusicDeviceInstrumentID for the desired MIKMIDIEndpointSynthesizerInstrument
 *
 *  @return A MIKMIDIEndpointSynthesizerInstrument with the matching instrument ID, or nil if no instrument was found.
 */
+ (instancetype)instrumentWithID:(MusicDeviceInstrumentID)instrumentID;

/**
 *  The human readable name of the receiver. e.g. "Piano 1".
 */
@property (readonly, copy, nonatomic) NSString *name;

/**
 *  The Core Audio supplied instrumentID for the receiver.
 */
@property (readonly, nonatomic) MusicDeviceInstrumentID instrumentID;

@end
