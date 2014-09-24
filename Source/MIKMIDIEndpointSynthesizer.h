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

@class MIKMIDISourceEndpoint;
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
 *  The source the receive is listening to.
 */
@property (nonatomic, strong, readonly) MIKMIDISourceEndpoint *source;


/**
 * An array of MIKMIDIEndpointSnythesizerInstruments
 */
- (NSArray *)availableInstruments;


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

@end



@interface MIKMIDIEndpointSynthesizerInstrument : NSObject

@property (readonly, copy, nonatomic) NSString *name;
@property (readonly, nonatomic) MusicDeviceInstrumentID instrumentID;

+ (instancetype)instrumentWithName:(NSString *)name instrumentID:(MusicDeviceInstrumentID)instrumentID;

@end

#endif // !TARGET_OS_IPHONE