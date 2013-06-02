//
//  MIKMIDIInputPort.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPort.h"

@class MIKMIDIEndpoint;
@class MIKMIDISourceEndpoint;

typedef void(^MIKMIDIEventHandlerBlock)(MIKMIDISourceEndpoint *source, NSArray *commands); // commands in an array of MIKMIDICommands

@interface MIKMIDIInputPort : MIKMIDIPort

- (BOOL)connectToSource:(MIKMIDISourceEndpoint *)source error:(NSError **)error;
- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source;

@property (nonatomic, strong, readonly) NSArray *connectedSources;

@property (nonatomic, strong, readonly) NSSet *eventHandlers;
- (void)addEventHandler:(MIKMIDIEventHandlerBlock)eventHandler;
- (void)removeEventHandler:(MIKMIDIEventHandlerBlock)eventHandler;
- (void)removeAllEventHandlers;

@end
