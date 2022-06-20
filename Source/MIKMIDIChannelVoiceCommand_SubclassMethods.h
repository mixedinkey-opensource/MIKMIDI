//
//  MIKMIDIChannelVoiceCommand_SubclassMethods.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 10/10/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#ifdef SWIFTPM
#import "MIKMIDIChannelVoiceCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"
#import "MIKMIDICompilerCompatibility.h"
#else
#import <MIKMIDI/MIKMIDIChannelVoiceCommand.h>
#import <MIKMIDI/MIKMIDICommand_SubclassMethods.h>
#import <MIKMIDI/MIKMIDICompilerCompatibility.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDIChannelVoiceCommand ()

@property (nonatomic, readwrite) NSUInteger value;

@end

NS_ASSUME_NONNULL_END
