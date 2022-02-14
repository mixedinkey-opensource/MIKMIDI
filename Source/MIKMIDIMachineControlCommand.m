//
//  MIKMIDIMachineControlCommand.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/13/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMachineControlCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

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
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDISystemExclusiveCommand class]; }

@end

@implementation MIKMutableMIDIMachineControlCommand

@end
