//
//  MIKMIDIControlChangeCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIChannelVoiceCommand.h"

@interface MIKMIDIControlChangeCommand : MIKMIDIChannelVoiceCommand

+ (instancetype)commandByCoalescingMSBCommand:(MIKMIDIControlChangeCommand *)msbCommand andLSBCommand:(MIKMIDIControlChangeCommand *)lsbCommand;

@property (nonatomic, readonly) NSUInteger controllerNumber;
@property (nonatomic, readonly) NSUInteger controllerValue;

@property (nonatomic, readonly, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end

@interface MIKMutableMIDIControlChangeCommand : MIKMutableMIDIChannelVoiceCommand

@property (nonatomic, readwrite) NSUInteger controllerNumber;
@property (nonatomic, readwrite) NSUInteger controllerValue;

@property (nonatomic, readwrite, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end