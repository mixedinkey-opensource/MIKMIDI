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

@interface MIKMIDIPort : NSObject

- (id)initWithClient:(MIDIClientRef)clientRef name:(NSString *)name;

@property (nonatomic, readonly) MIDIPortRef portRef;

@end
