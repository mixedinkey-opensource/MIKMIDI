//
//  MIKMIDIMachineControlLocateTargetCommand.m
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/6/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMachineControlLocateTargetCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@implementation MIKMIDIMachineControlLocateTargetCommand

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
    uint8_t messageTypeIndex = directionByteIndex + 1;
    if (packet->length <= messageTypeIndex) { return MIKMIDICommandPacketHandlingIntentReject; }

    uint8_t messageType = packet->data[messageTypeIndex];

    if (messageType == 0x44) { return MIKMIDICommandPacketHandlingIntentAcceptWithHigherPrecedence; }
    return MIKMIDICommandPacketHandlingIntentReject;
}

+ (Class)immutableCounterpartClass; { return [MIKMIDIMachineControlLocateTargetCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDISystemExclusiveCommand class]; }

@end
