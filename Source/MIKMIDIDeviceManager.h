//
//  MIKMIDIDeviceManager.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIKMIDIInputPort.h"

@class MIKMIDISourceEndpoint;
@class MIKMIDIDestinationEndpoint;
@class MIKMIDICommand;

// Notifications
extern NSString * const MIKMIDIDeviceWasAddedNotification;
extern NSString * const MIKMIDIDeviceWasRemovedNotification;
extern NSString * const MIKMIDIVirtualEndpointWasAddedNotification;
extern NSString * const MIKMIDIVirtualEndpointWasRemovedNotification;

// Notification Keys
extern NSString * const MIKMIDIDeviceKey;
extern NSString * const MIKMIDIEndpointKey;

@interface MIKMIDIDeviceManager : NSObject

+ (instancetype)sharedDeviceManager;

- (BOOL)connectInput:(MIKMIDISourceEndpoint *)endpoint error:(NSError **)error eventHandler:(MIKMIDIEventHandlerBlock)eventHandler;
- (void)disconnectInput:(MIKMIDISourceEndpoint *)endpoint;

- (BOOL)sendCommands:(NSArray *)commands toEndpoint:(MIKMIDIDestinationEndpoint *)endpoint error:(NSError **)error;

@property (nonatomic, readonly) NSArray *availableDevices; // Array of MIKMIDIDevices
@property (nonatomic, readonly) NSArray *virtualSources; // Array of MIKMIDISourceEndpoints
@property (nonatomic, readonly) NSArray *virtualDestinations; // Array of MIKMIDIDestinationEndpoints

@property (nonatomic, readonly) NSArray *connectedInputSources; // Array of MIKMIDISourceEndpoints

@end
