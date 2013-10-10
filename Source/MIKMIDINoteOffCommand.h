//
//  MIKMIDINoteOffCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelVoiceCommand.h"

@interface MIKMIDINoteOffCommand : MIKMIDIChannelVoiceCommand

@property (nonatomic, readonly) NSUInteger note;
@property (nonatomic, readonly) NSUInteger velocity;

@end

@interface MIKMutableMIDINoteOffCommand : MIKMIDINoteOffCommand

@property (nonatomic, readwrite) NSUInteger note;
@property (nonatomic, readwrite) NSUInteger velocity;

@end