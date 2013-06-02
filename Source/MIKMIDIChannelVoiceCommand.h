//
//  MIKMIDIChannelVoiceCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDICommand.h"

@interface MIKMIDIChannelVoiceCommand : MIKMIDICommand

@property (nonatomic, readonly) UInt8 channel;

@end

@interface MIKMutableMIDIChannelVoiceCommand : MIKMutableMIDICommand

@property (nonatomic, readwrite) UInt8 channel;

@end
