//
//  MIKMIDIClientSourceEndpoint.h
//  MIKMIDI
//  
//  Created by Dan Rosenstark on 2015-01-07
//

#import "MIKMIDISourceEndpoint.h"

@interface MIKMIDIClientSourceEndpoint : MIKMIDISourceEndpoint

- (instancetype)initWithName:(NSString*)name;

/**
 *  Used to send MIDI messages/commands from your application to a MIDI output endpoint.
 *  Use this to send messages to a virtual MIDI port created in the  your client using the MIKMIDIClientSourceEndpoint class.
 *
 *  @param commands An NSArray containing MIKMIDICommand instances to be sent.
 *  @param error    If an error occurs, upon returns contains an NSError object that describes the problem. If you are not interested in possible errors, you may pass in NULL.
 *
 *  @return YES if the commands were successfully sent, NO if an error occurred.
 */
- (BOOL)sendCommands:(NSArray *)commands error:(NSError **)error;

@end
