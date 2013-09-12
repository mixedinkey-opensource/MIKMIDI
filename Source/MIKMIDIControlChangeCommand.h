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

/**
 *  The MIDI control number for the command.
 */
@property (nonatomic, readonly) NSUInteger controllerNumber;

/**
 *  The controlValue of the command. 
 *
 *  This method returns the same value as -value. Note that this is always a 7-bit (0-127)
 *  value, even for a fourteen bit command. To retrieve the 14-bit value, use -fourteenBitValue.
 *
 *  @see -fourteenBitCommand
 */
@property (nonatomic, readonly) NSUInteger controllerValue;

/**
 *  The 14-bit value of the command.
 *
 *  This property always returns a 14-bit value (ranging from 0-16383). If the receiver is
 *  not a coalesced 14-bit command (-isFourteenBitCommand returns NO), the 7 least significant
 *  bits will always be 0.
 */
@property (nonatomic, readonly) NSUInteger fourteenBitValue;

/**
 *  YES if the command is coalesced from two commands making up a 14-bit MIDI control change
 *  command.
 *
 *  If this property returns YES, -fourteenBitValue will return a precision, 
 */
@property (nonatomic, readonly, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end

@interface MIKMutableMIDIControlChangeCommand : MIKMutableMIDIChannelVoiceCommand

@property (nonatomic, readwrite) NSUInteger controllerNumber;
@property (nonatomic, readwrite) NSUInteger controllerValue;

/**
 *  The 14-bit value of the command.
 *
 *  This property always returns a 14-bit value (ranging from 0-16383). If the receiver is
 *  not a coalesced 14-bit command (-isFourteenBitCommand returns NO), the 7 least significant
 *  bits will always be 0, and will be discarded when setting this property.
 */
@property (nonatomic, readwrite) NSUInteger fourteenBitValue;

@property (nonatomic, readwrite, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end