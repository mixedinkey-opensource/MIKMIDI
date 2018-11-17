//
//  MIKMIDIInputPortTests.m
//  MIKMIDI Tests
//
//  Created by Andrew R Madsen on 2/9/18.
//  Copyright © 2018 Mixed In Key. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <MIKMIDI/MIKMIDI.h>

@interface MIKMIDIDeviceManager (Private)
@property (nonatomic, strong) MIKMIDIInputPort *inputPort;
@end

@interface MIKMIDIInputPort (Private)
- (void)interpretPacketList:(const MIDIPacketList *)pktList handleResultingCommands:(void (^_Nonnull)(NSArray <MIKMIDICommand*> *receivedCommands))completionBlock;
@end

@interface MIKMIDIInputPortTests : XCTestCase

@end

@implementation MIKMIDIInputPortTests

- (void)testReceivingMachineControlCommands
{
	MIKMutableMIDISystemExclusiveCommand *mmcCommand = [[MIKMutableMIDISystemExclusiveCommand alloc] init];
	mmcCommand.manufacturerID = kMIKMIDISysexRealtimeManufacturerID;
	mmcCommand.sysexChannel = kMIKMIDISysexChannelDisregard;
	mmcCommand.sysexData = [NSData dataWithBytes:(UInt8[]){0x06, 0x44, 0x06, 0x01, 0x21, 0x02, 0x3A, 0x00, 0x00, 0xf7} length:10];
	
	MIDIPacket *packet = MIKMIDIPacketCreateFromCommands(mmcCommand.midiTimestamp, @[mmcCommand]);;
	MIDIPacketList list = {0};
	list.numPackets = 1;
	list.packet[0] = *packet;
	
	MIKMIDIInputPort *port = [[MIKMIDIDeviceManager sharedDeviceManager] inputPort];
	[port interpretPacketList:&list handleResultingCommands:^(NSArray<MIKMIDICommand *> *receivedCommands) {
		XCTAssertEqualObjects(receivedCommands.firstObject, mmcCommand);
	}];
}

@end
