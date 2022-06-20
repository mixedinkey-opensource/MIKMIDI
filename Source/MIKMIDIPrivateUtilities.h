//
//  MIKMIDIPrivateUtilities.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 11/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef SWIFTPM
#import "MIKMIDICompilerCompatibility.h"
#else
#import <MIKMIDI/MIKMIDICompilerCompatibility.h>
#endif

@class MIKMIDIChannelVoiceCommand;

NS_ASSUME_NONNULL_BEGIN

NSUInteger MIKMIDIControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command);
float MIKMIDIControlValueFromChannelVoiceCommand(MIKMIDIChannelVoiceCommand *command);

NS_ASSUME_NONNULL_END
