//
//  MIKMIDIControlChangeCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelVoiceCommand.h"

@interface MIKMIDIControlChangeCommand : MIKMIDIChannelVoiceCommand

@property (nonatomic, readonly) NSUInteger controllerNumber;
@property (nonatomic, readonly) NSUInteger controllerValue;

@end

@interface MIKMutableMIDIControlChangeCommand : MIKMutableMIDIChannelVoiceCommand

@property (nonatomic, readwrite) NSUInteger controllerNumber;
@property (nonatomic, readwrite) NSUInteger controllerValue;

@end