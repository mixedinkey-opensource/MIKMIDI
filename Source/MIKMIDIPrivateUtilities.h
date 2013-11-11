//
//  MIKMIDIPrivateUtilities.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 11/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDIChannelVoiceCommand;

NSUInteger MIKMIDIControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command);
float MIKMIDIControlValueFromChannelVoiceCommand(MIKMIDIChannelVoiceCommand *command);
