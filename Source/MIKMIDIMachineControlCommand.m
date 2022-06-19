//
//  MIKMIDIMachineControlCommand.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/13/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMachineControlCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"
#import "MIKMMCLocateTargetCommand.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMIDIMachineControlCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (NSArray *)supportedMIDICommandTypes { return @[@(MIKMIDICommandTypeSystemExclusive)]; }

+ (MIKMIDICommandPacketHandlingIntent)handlingIntentForMIDIPacket:(MIDIPacket *)packet
{
    if (packet->length < 5) { return MIKMIDICommandPacketHandlingIntentReject; }
    uint8_t directionByteIndex = 3;
    uint8_t firstByte = packet->data[1];
    if (firstByte == 0) { // Three byte manufacturer ID
        directionByteIndex += 2;
    }
    uint8_t directionByte = packet->data[directionByteIndex];
    if (directionByte != 0x06 && directionByte != 0x07) { return MIKMIDICommandPacketHandlingIntentReject; }

    return MIKMIDICommandPacketHandlingIntentAccept;
}

+ (Class)immutableCounterpartClass; { return [MIKMIDIMachineControlCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIMachineControlCommand class]; }

- (id)initWithMIDIPacket:(MIDIPacket *)packet
{
    self = [super initWithMIDIPacket:packet];
    if (self) {
        if (!packet) {
            if ([self.internalData length] < 5) {
                [self.internalData increaseLengthBy:5-[self.internalData length]];
            }
            UInt8 *data = (UInt8 *)[self.internalData mutableBytes];
            data[0] = 0xf0;
            data[1] = 0x7f; // Sysex start
            data[2] = 0x7f; // generic device address
            data[3] = MIKMIDIMachineControlDirectionCommand;
            data[4] = MIKMIDIMachineControlCommandTypeUnknown;
        }
    }
    return self;
}

+ (instancetype)machineControlCommandWithDeviceAddress:(UInt8)deviceAddress
                                             direction:(MIKMIDIMachineControlDirection)direction
                                        MMCCommandType:(MIKMIDIMachineControlCommandType)mmcCommandType
{
    Class resultClass = [MIKMIDIMachineControlCommand class];
    if (mmcCommandType == MIKMIDIMachineControlCommandTypeLocate) { resultClass = [MIKMMCLocateTargetCommand class]; }

    MIKMutableMIDIMachineControlCommand *result = [[[resultClass mutableCounterpartClass] alloc] init];
    result.deviceAddress = deviceAddress;
    result.direction = direction;
    result.MMCCommandType = mmcCommandType;

    return [self isMutable] ? result : [result copy];
}

#pragma mark - Properties

- (UInt8)deviceAddress
{
    UInt8 deviceIDByteIndex = self.includesThreeByteManufacturerID ? 4 : 2;
    UInt8 deviceID = ((UInt8 *)self.data.bytes)[deviceIDByteIndex];
    return deviceID;
}

- (void)setDeviceAddress:(UInt8)deviceAddress
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;

    UInt8 deviceIDByteIndex = self.includesThreeByteManufacturerID ? 4 : 2;
    if ([self.internalData length] <= deviceIDByteIndex) {
        [self.internalData increaseLengthBy:deviceIDByteIndex + 1 - [self.internalData length]];
    }

    UInt8 *data = (UInt8 *)[self.internalData mutableBytes];
    data[deviceIDByteIndex] = deviceAddress;
}

- (MIKMIDIMachineControlDirection)direction
{
    UInt8 directionByteIndex = self.includesThreeByteManufacturerID ? 5 : 3;
    MIKMIDIMachineControlDirection direction = ((UInt8 *)self.data.bytes)[directionByteIndex];
    return direction;
}

- (void)setDirection:(MIKMIDIMachineControlDirection)direction
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;

    UInt8 directionByteIndex = self.includesThreeByteManufacturerID ? 5 : 3;
    if ([self.internalData length] <= directionByteIndex) {
        [self.internalData increaseLengthBy:directionByteIndex + 1 - [self.internalData length]];
    }

    UInt8 *data = (UInt8 *)[self.internalData mutableBytes];
    data[directionByteIndex] = direction;
}

- (MIKMIDIMachineControlCommandType)MMCCommandType
{
    UInt8 commandTypeByteIndex = self.includesThreeByteManufacturerID ? 6 : 4;
    MIKMIDIMachineControlCommandType commandType = ((UInt8 *)self.data.bytes)[commandTypeByteIndex];
    return commandType;
}

- (void)setMMCCommandType:(MIKMIDIMachineControlCommandType)MMCCommandType
{
    if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;

    UInt8 commandTypeByteIndex = self.includesThreeByteManufacturerID ? 6 : 4;
    if ([self.internalData length] <= commandTypeByteIndex) {
        [self.internalData increaseLengthBy:commandTypeByteIndex + 1 - [self.internalData length]];
    }

    UInt8 *data = (UInt8 *)[self.internalData mutableBytes];
    data[commandTypeByteIndex] = MMCCommandType;
}

@end

@implementation MIKMutableMIDIMachineControlCommand

+ (BOOL)isMutable { return YES; }

#pragma mark - Properties

@dynamic deviceAddress;
@dynamic direction;
@dynamic MMCCommandType;

// MIKMIDICommand already implements these. This keeps the compiler happy.
@dynamic timestamp;
@dynamic dataByte1;
@dynamic dataByte2;
@dynamic midiTimestamp;
@dynamic data;
@dynamic commandType;

@end
