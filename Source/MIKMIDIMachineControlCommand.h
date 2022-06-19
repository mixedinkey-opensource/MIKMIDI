//
//  MIKMIDIMachineControlCommand.h
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/13/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDISystemExclusiveCommand.h>

/**
 * The MMC sub-ID.
 * As defined by the MMC spec, a message can be either a command or a response.
 */
typedef NS_ENUM(UInt8, MIKMIDIMachineControlDirection) {
    MIKMIDIMachineControlDirectionCommand = 0x06, // aka. 'mcc'
    MIKMIDIMachineControlDirectionResponse = 0x07, // aka. 'mcr'
};

/**
 * The possible command types represented by an MMC message. These are set forth and described in the
 * MMC part of the MIDI spec.
 */
typedef NS_ENUM(UInt8, MIKMIDIMachineControlCommandType) {
    MIKMIDIMachineControlCommandTypeUnknown = 0x00,

    MIKMIDIMachineControlCommandTypeStop = 0x01,
    MIKMIDIMachineControlCommandTypePlay = 0x02,
    MIKMIDIMachineControlCommandTypeDeferredPlay = 0x03,
    MIKMIDIMachineControlCommandTypeFastForward = 0x04,
    MIKMIDIMachineControlCommandTypeRewind = 0x05,
    MIKMIDIMachineControlCommandTypeRecordStrobe = 0x06,
    MIKMIDIMachineControlCommandTypeRecordExit = 0x07,
    MIKMIDIMachineControlCommandTypeRecordPause = 0x08,
    MIKMIDIMachineControlCommandTypePause = 0x09,
    MIKMIDIMachineControlCommandTypeEject = 0x0a,
    MIKMIDIMachineControlCommandTypeChase = 0x0b,
    MIKMIDIMachineControlCommandTypeCommandErrorReset = 0xc,
    MIKMIDIMachineControlCommandTypeMMCRest = 0xd,
    MIKMIDIMachineControlCommandTypeWrite = 0x40,
    MIKMIDIMachineControlCommandTypeMaskedWrite = 0x41,
    MIKMIDIMachineControlCommandTypeRead = 0x42,
    MIKMIDIMachineControlCommandTypeUpdate = 0x43,
    MIKMIDIMachineControlCommandTypeLocate = 0x44,
    MIKMIDIMachineControlCommandTypeVariablePlay = 0x45,
    MIKMIDIMachineControlCommandTypeSearch = 0x46,
    MIKMIDIMachineControlCommandTypeShuttle = 0x47,
    MIKMIDIMachineControlCommandTypeStep = 0x48,
    MIKMIDIMachineControlCommandTypeAssignSystemMaster = 0x49,
    MIKMIDIMachineControlCommandTypeGeneratorCommand = 0x4a,
    MIKMIDIMachineControlCommandTypeMIDITimeCodeCommand = 0x4b,
    MIKMIDIMachineControlCommandTypeMove = 0x4c,
    MIKMIDIMachineControlCommandTypeAdd = 0x4d,
    MIKMIDIMachineControlCommandTypeSubtract = 0x4e,
    MIKMIDIMachineControlCommandTypeDropFrameAdjust = 0x4f,
    MIKMIDIMachineControlCommandTypeProcedure = 0x50,
    MIKMIDIMachineControlCommandTypeEvent = 0x51,
    MIKMIDIMachineControlCommandTypeGroup = 0x52,
    MIKMIDIMachineControlCommandTypeCommandSegment = 0x53,
    MIKMIDIMachineControlCommandTypeDeferredVariablePlay = 0x54,
    MIKMIDIMachineControlCommandTypeRecordStrobeVariable = 0x55,
    MIKMIDIMachineControlCommandTypeWait = 0x7C,
    MIKMIDIMachineControlCommandTypeResume = 0x7F,
};

NS_ASSUME_NONNULL_BEGIN

/**
 *  MIKMIDIMachineControlCommand is used to represent MIDI messages that are used for
 *  MIDI Machine Control (MMC), per the MIDI spec. Specific support for MMC command
 *  subtypes is provided by subclasses of MIKMIDIMachineControlCommand (e.g.
 *  MIKMIDIMachineControlLocatedTargetCommand, etc.)
 */
@interface MIKMIDIMachineControlCommand : MIKMIDISystemExclusiveCommand

/**
 * Convenience method for creating a machine control command.
 *
 * @param deviceAddress The device address for the command. Destination address for commands, source address for responses
 * @param direction The direction the command is going, either a command or a response
 * @param mmcCommandType The sub-type for the command. See MIKMIDIMachineControlCommandType for values
 *
 * @return An initialized MIKMIDIMachineControlCommand (or subclass) instance
 */
+ (instancetype)machineControlCommandWithDeviceAddress:(UInt8)deviceAddress
                                             direction:(MIKMIDIMachineControlDirection)direction
                                        MMCCommandType:(MIKMIDIMachineControlCommandType)mmcCommandType;


/**
 * The device address in the message represented by the receiver. Per the MMC spec, this is the destination
 * device for commands, and the source device address for responses.
 */
@property (nonatomic, readonly) UInt8 deviceAddress;

/**
 * The direction this message is going. As defined by the MMC spec, a message can be either a command
 * or a response. See MIKMIDIMachineControlDirection for possible values.
 */
@property (nonatomic, readonly) MIKMIDIMachineControlDirection direction;

/**
 * The MMC command type represented by the receiver. For a complete list of possible values
 * see MIKMIDIMachineControlCommandType.
 */
@property (nonatomic, readonly) MIKMIDIMachineControlCommandType MMCCommandType;

@end

/**
 *  The mutable counterpart of MIKMIDIMachineControlCommand.
 */
@interface MIKMutableMIDIMachineControlCommand : MIKMIDIMachineControlCommand

@property (nonatomic, readwrite) UInt8 deviceAddress;
@property (nonatomic, readwrite) MIKMIDIMachineControlDirection direction;
@property (nonatomic, readwrite) MIKMIDIMachineControlCommandType MMCCommandType;

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite, null_resettable) NSData *data;

@end

NS_ASSUME_NONNULL_END
