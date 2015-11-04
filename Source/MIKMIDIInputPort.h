//
//  MIKMIDIInputPort.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPort.h"
#import "MIKMIDICompilerCompatibility.h"

@class MIKMIDIEndpoint;
@class MIKMIDISourceEndpoint;
@class MIKMIDICommand;

NS_ASSUME_NONNULL_BEGIN

typedef void(^MIKMIDIEventHandlerBlock)(MIKMIDISourceEndpoint *source, MIKArrayOf(MIKMIDICommand *) *commands); // commands in an array of MIKMIDICommands

/**
 *  MIKMIDIInputPort is an Objective-C wrapper for CoreMIDI's MIDIPort class, and is only for source ports.
 *  It is not intended for use by clients/users of of MIKMIDI. Rather, it should be thought of as an
 *  MIKMIDI private class.
 */
@interface MIKMIDIInputPort : MIKMIDIPort

- (BOOL)connectToSource:(MIKMIDISourceEndpoint *)source error:(NSError **)error;
- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source;

@property (nonatomic, strong, readonly) MIKArrayOf(MIKMIDIEndpoint *) *connectedSources;

@property (nonatomic, strong, readonly) NSSet *eventHandlers;
- (id)addEventHandler:(MIKMIDIEventHandlerBlock)eventHandler; // Returns a token
- (void)removeEventHandlerForToken:(id)token;
- (void)removeAllEventHandlers;

@property (nonatomic) BOOL coalesces14BitControlChangeCommands; // Default is YES

@end

NS_ASSUME_NONNULL_END