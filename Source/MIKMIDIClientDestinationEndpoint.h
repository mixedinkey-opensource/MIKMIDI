//
//  MIKMIDIClientDestinationEndpoint.h
//  Pods
//
//  Created by Andrew Madsen on 9/26/14.
//
//

#import "MIKMIDIDestinationEndpoint.h"

@class MIKMIDIClientDestinationEndpoint;

typedef void(^MIKMIDIClientDestinationEndpointEventHandler)(MIKMIDIClientDestinationEndpoint *destination, NSArray *commands);

@interface MIKMIDIClientDestinationEndpoint : MIKMIDIDestinationEndpoint

/**
 *  Initializes a new virtual destination endpoint.
 *  This is essentially equivalent to creating a Core MIDI destination endpoint
 *  using MIDIDestinationCreate(). Destination endpoints created using this
 *  method can be used by your application to *receive* MIDI rather than send
 *  it. They can be seen and connected to by other applications on the system.
 */
- (instancetype)initWithName:(NSString *)name receivedMessagesHandler:(MIKMIDIClientDestinationEndpointEventHandler)handler;

@property (nonatomic, strong) MIKMIDIClientDestinationEndpointEventHandler receivedMessagesHandler;

@end
