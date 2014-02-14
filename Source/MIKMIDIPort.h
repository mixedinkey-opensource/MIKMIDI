//
//  MIKMIDIPort.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIObject.h"
#import <CoreMIDI/CoreMIDI.h>

@class MIKMIDIEndpoint;

/**
 *  MIKMIDIPort is an Objective-C wrapper for CoreMIDI's MIDIPort class. It is not intended for use by clients/users of
 *  of MIKMIDI. Rather, it should be thought of as an MIKMIDI private class.
 */
@interface MIKMIDIPort : NSObject

- (id)initWithClient:(MIDIClientRef)clientRef name:(NSString *)name;

@property (nonatomic, readonly) MIDIPortRef portRef;

@end
