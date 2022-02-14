//
//  MIKMMCLocateTargetCommand.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/6/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import "MIKMMCLocateTargetCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"
#import "MIKMIDIUtilities.h"

@implementation MIKMMCLocateTargetCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (NSArray *)supportedMIDICommandTypes { return @[@(MIKMIDICommandTypeSystemExclusive)]; }

+ (MIKMIDICommandPacketHandlingIntent)handlingIntentForMIDIPacket:(MIDIPacket *)packet
{
    if (packet->length < 5) { return MIKMIDICommandPacketHandlingIntentReject; }
    UInt8 directionByteIndex = 3;
    UInt8 firstByte = packet->data[1];
    if (firstByte == 0) { // Three byte manufacturer ID
        directionByteIndex += 2;
    }
    UInt8 messageTypeIndex = directionByteIndex + 1;
    if (packet->length <= messageTypeIndex) { return MIKMIDICommandPacketHandlingIntentReject; }

    UInt8 messageType = packet->data[messageTypeIndex];

    if (messageType == 0x44) { return MIKMIDICommandPacketHandlingIntentAcceptWithHigherPrecedence; }

    UInt8 subtypeIndex = messageTypeIndex + 2;
    if (packet->length <= subtypeIndex) { return MIKMIDICommandPacketHandlingIntentReject; }

    UInt8 subtype = packet->data[subtypeIndex];
    if (subtype != 0x01) { return MIKMIDICommandPacketHandlingIntentReject; } // Otherwise, it's not a target command

    return MIKMIDICommandPacketHandlingIntentReject;
}

+ (Class)immutableCounterpartClass; { return [MIKMMCLocateTargetCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMMCLocateTargetCommand class]; }

- (id)initWithMIDIPacket:(MIDIPacket *)packet
{
    self = [super initWithMIDIPacket:packet];
    if (self) {
        if (!packet) {
            if ([self.internalData length] < 5) {
                [self.internalData increaseLengthBy:5-[self.internalData length]];
            }
            UInt8 *data = (UInt8 *)[self.internalData mutableBytes];
            data[4] = MIKMIDIMachineControlCommandTypeLocate;
        }
    }
    return self;
}

+ (instancetype)locateTargetCommandWithTimeCodeInSeconds:(NSTimeInterval)timecode
                                                timeType:(MIKMMCLocateTargetCommandTimeType)timeType
{
    MIKMutableMMCLocateTargetCommand *result = [[MIKMutableMMCLocateTargetCommand alloc] init];
    result.timeType = timeType;
    result.timeCodeInSeconds = timecode;
    return [self isMutable] ? result : [result copy];
}

- (NSString *)additionalCommandDescription
{
    return [NSString stringWithFormat:@"timecode: %@", @(self.timeCodeInSeconds)];
}

#pragma mark - Properties

#pragma mark Public

- (NSTimeInterval)timeCodeInSeconds
{
    NSData *timecodeData = [self timecodeData];
    if (!timecodeData) { return -1; }

    UInt8 *timecodeBytes = (UInt8 *)timecodeData.bytes;
    UInt8 hoursAndTypeByte = timecodeBytes[0];
    UInt8 minutesByte = timecodeBytes[1];
    UInt8 secondsByte = timecodeBytes[2];
    UInt8 framesByte = timecodeBytes[3];
    UInt8 finalByte = timecodeBytes[4];

    UInt8 hours = (hoursAndTypeByte & 0x1F);
    NSTimeInterval frameRate = [self frameRate];

//    UInt8 colorFrameFlag = (minutesByte & 0x40) >> 6;
    UInt8 minutes = (minutesByte & 0x3F);

//    UInt8 blankBit = (secondsByte & 0x40) >> 6;
    UInt8 seconds = (secondsByte & 0x3F);

    UInt8 sign = (framesByte & 0x40) >> 6;
    UInt8 finalByteID = (framesByte & 0x20) >> 5;
    UInt8 frames = (framesByte & 0x1F);

    NSTimeInterval result = 0.0;

    result += hours * 3600.0;
    result += minutes * 60.0;
    result += seconds;
    result += (NSTimeInterval)frames / frameRate;

    if (finalByteID == 0) {
        UInt8 subframes = finalByte;
        // Final byte is subframes
        result += ((NSTimeInterval)subframes/100.0) / frameRate;
    }

    if (sign) {
        result = -result;
    }

    return result;
}

- (void)setTimeCodeInSeconds:(NSTimeInterval)timeCodeInSeconds
{
    if (![[self class] isMutable]) { return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION; }

    NSTimeInterval frameRate = [self frameRate];

    UInt8 hours = (UInt8)(timeCodeInSeconds / 3600.0) & 0x1F; // Hours
    UInt8 minutes = (UInt8)((timeCodeInSeconds - hours * 3600) / 60);
    UInt8 seconds = (UInt8)(timeCodeInSeconds - hours * 3600 - minutes * 60);
    UInt8 frames = (UInt8)((timeCodeInSeconds - hours * 3600 - minutes * 60 - seconds) * frameRate);
    UInt8 subframes = (UInt8)((timeCodeInSeconds - hours * 3600 - minutes * 60 - seconds - (NSTimeInterval)frames/frameRate) * 100.0);

    NSMutableData *newTimecodeData = [NSMutableData dataWithLength:5];
    UInt8 *timecodeBytes = (UInt8 *)newTimecodeData.mutableBytes;
    timecodeBytes[0] = ((self.timeType & 0x03) << 5) + hours;
    timecodeBytes[1] = (timecodeBytes[1] & 0xC0) | (minutes & 0x3F);
    timecodeBytes[2] = (timecodeBytes[2] & 0xC0) | (seconds & 0x3F);
    timecodeBytes[3] = (timecodeBytes[2] & 0xE0) | (frames & 0x1F);
    timecodeBytes[3] &= 0xDF; // set final byte ID to 0 for subframes
    timecodeBytes[4] = subframes;
    [self setTimecodeData:newTimecodeData];
}

- (MIKMMCLocateTargetCommandTimeType)timeType
{
    NSData *timecodeData = [self timecodeData];
    if (timecodeData.length < 1) { return MIKMMCLocateTargetCommandTimeType30FPS; }

    UInt8 *timecodeBytes = (UInt8 *)timecodeData.bytes;
    UInt8 hoursAndTypeByte = timecodeBytes[0];

    MIKMMCLocateTargetCommandTimeType type = (hoursAndTypeByte & 0x60) >> 5;
    return type;
}

- (void)setTimeType:(MIKMMCLocateTargetCommandTimeType)timeType
{
    if (![[self class] isMutable]) { return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION; }

    NSMutableData *timecodeData = [[self timecodeData] mutableCopy];
    if (!timecodeData) {
        timecodeData = [NSMutableData dataWithLength:5];
    }
    UInt8 *timecodeBytes = (UInt8 *)timecodeData.mutableBytes;
    timecodeBytes[0] = (timecodeBytes[0] & 0x9F) + ((timeType & 0x03) << 5);
    [self setTimecodeData:timecodeData];
}

#pragma mark Private

- (NSTimeInterval)frameRate
{
    switch ([self timeType]) {
        case MIKMMCLocateTargetCommandTimeType24FPS:
            return 24.0;
            break;
        case MIKMMCLocateTargetCommandTimeType25FPS:
            return 25.0;
        case MIKMMCLocateTargetCommandTimeType30FPSDropFrame: // Not currently handling drop frame rates exactly correctly
            return 29.97;
        default:
        case MIKMMCLocateTargetCommandTimeType30FPS:
            return 30.0;
    }
}

- (NSData *)timecodeData
{
    NSUInteger byteCountIndex = 5;
    if (self.includesThreeByteManufacturerID) {
        byteCountIndex += 2;
    }
    if (self.data.length <= byteCountIndex) { return nil; }

    UInt8 byteCount = ((UInt8 *)self.data.bytes)[byteCountIndex];
    if (self.data.length < (byteCountIndex + byteCount)) { return nil; }

    UInt8 subcommandIndex = byteCountIndex += 1;
    UInt8 subcommand = ((UInt8 *)self.data.bytes)[subcommandIndex];
    if (subcommand != 0x01) { return nil; } // Not a locate target command

    NSUInteger timecodeDataLocation = subcommandIndex+1;
    NSData *timecodeData = [self.data subdataWithRange:NSMakeRange(timecodeDataLocation, byteCount-1)];
    return timecodeData;
}

- (void)setTimecodeData:(NSData *)data
{
    NSUInteger requiredLength = 13;
    if (self.includesThreeByteManufacturerID) { requiredLength += 2; }
    if ([self.internalData length] < requiredLength) {
        [self.internalData increaseLengthBy:requiredLength - [self.internalData length]];
    }

    NSUInteger byteCountIndex = 5;
    if (self.includesThreeByteManufacturerID) {
        byteCountIndex += 2;
    }
    ((UInt8 *)self.internalData.mutableBytes)[byteCountIndex] = 6;

    UInt8 subcommandIndex = byteCountIndex += 1;
    ((UInt8 *)self.internalData.mutableBytes)[subcommandIndex] = 0x01;

    NSUInteger timecodeDataLocation = subcommandIndex+1;
    [self.internalData replaceBytesInRange:NSMakeRange(timecodeDataLocation, 5)
                                 withBytes:data.bytes length:data.length];
}

@end

@implementation MIKMutableMMCLocateTargetCommand

+ (BOOL)isMutable { return YES; }

#pragma mark - Properties

@dynamic timeCodeInSeconds;
@dynamic timeType;

// MIKMIDICommand or MIKMIDIMachineControlCommand already implements these. This keeps the compiler happy.

@dynamic deviceAddress;
@dynamic direction;
@dynamic MMCCommandType;

@dynamic timestamp;
@dynamic dataByte1;
@dynamic dataByte2;
@dynamic midiTimestamp;
@dynamic data;
@dynamic commandType;

@end
