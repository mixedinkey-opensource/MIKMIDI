//
//  MIKMIDIControlChangeCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDIChannelVoiceCommand_SubclassMethods.h"

#if !__has_feature(objc_arc)
#error MIKMIDIControlChangeCommand.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIControlChangeCommand.m in the Build Phases for this target
#endif

@interface MIKMIDIControlChangeCommand ()

@property (nonatomic, readwrite) NSUInteger controllerNumber;
@property (nonatomic, readwrite) NSUInteger controllerValue;

@property (nonatomic, readwrite) NSUInteger fourteenBitValue;
@property (nonatomic, readwrite, getter = isFourteenBitCommand) BOOL fourteenBitCommand;

@end

@implementation MIKMIDIControlChangeCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeControlChange; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIControlChangeCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIControlChangeCommand class]; }

+ (instancetype)commandByCoalescingMSBCommand:(MIKMIDIControlChangeCommand *)msbCommand andLSBCommand:(MIKMIDIControlChangeCommand *)lsbCommand;
{
	if (!msbCommand || !lsbCommand) return nil;
	
	if (![msbCommand isKindOfClass:[MIKMIDIControlChangeCommand class]] ||
		![lsbCommand isKindOfClass:[MIKMIDIControlChangeCommand class]]) return nil;
	
	if (msbCommand.controllerNumber > 31) return nil;
	if (lsbCommand.controllerNumber < 32 || lsbCommand.controllerNumber > 63) return nil;
	
	if (lsbCommand.controllerNumber - msbCommand.controllerNumber != 32) return nil;
	
	MIKMIDIControlChangeCommand *result = [[MIKMIDIControlChangeCommand alloc] init];
	result.internalData = [msbCommand.data mutableCopy];
	result.fourteenBitCommand = YES;
	[result.internalData appendData:[lsbCommand.data subdataWithRange:NSMakeRange(2, 1)]];
	
	return result;
}

- (id)initWithMIDIPacket:(MIDIPacket *)packet
{
	self = [super initWithMIDIPacket:packet];
	if (self) {
#ifndef DISABLE_CONTROLLER_SPECIFIC_WORKAROUNDS
		NSData *pioneer14BitData = [self fourteenBitDataFromPioneer5ByteData:self.internalData];
		if ([pioneer14BitData length]) {
			self.internalData = [pioneer14BitData mutableCopy];
			self.fourteenBitCommand = YES;
		}
#endif
	}
	return self;
}

-(NSString *)additionalCommandDescription
{
	if (self.isFourteenBitCommand) {
		return [NSString stringWithFormat:@"%@ control number: %lu value: %f 14-bit? %i", [super additionalCommandDescription], (unsigned long)self.controllerNumber, (float)self.fourteenBitValue / 128.0f, self.isFourteenBitCommand];
	} else {
		return [NSString stringWithFormat:@"%@ control number: %lu value: %lu 14-bit? %i", [super additionalCommandDescription], (unsigned long)self.controllerNumber, (unsigned long)self.controllerValue, self.isFourteenBitCommand];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIControlChangeCommand *result = [super copyWithZone:zone];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

- (id)mutableCopy
{
	MIKMIDIControlChangeCommand *result = [super mutableCopy];
	result.fourteenBitCommand = self.isFourteenBitCommand;
	return result;
}

#pragma mark - Private

#ifndef DISABLE_CONTROLLER_SPECIFIC_WORKAROUNDS

- (NSData *)fourteenBitDataFromPioneer5ByteData:(NSData *)data
{
	// Some Pioneer controller (e.g. DDJ-SX, SR, etc.) send 5 bytes of MIDI
	// data in their control change commands. This code attempts to detect that
	// and respond appropriately.
	// Returns nil if data doesn't appear to be from such a controller.
	
	// In essense, these Pioneer controllers send 14-bit data "pre-coalesced" into a single
	// message. The first 2 bytes (3 bytes including command type) are a standard MIDI command.
	// The last 3 bytes are essentially another CC command, complete with command type, controller number + 32,
	// and another byte of (LSB) data.
	
	if ([data length] != 6) return nil;
	
	uint8_t statusByte = *(uint8_t *)([data bytes] + 3);
	if ((statusByte & 0xF0) != (MIKMIDICommandTypeControlChange & 0xF0)) return nil; // Status byte's first nibble should be B for control change
	
	NSData *standardData = [data subdataWithRange:NSMakeRange(1, 2)];
	NSData *extendedData = [data subdataWithRange:NSMakeRange(4, 2)];
	
	uint8_t standardControllerNumber = *(uint8_t *)[standardData bytes];
	uint8_t extendedControllerNumber = *(uint8_t *)[extendedData bytes];
	
	// byte4 should be byte1 + 32 (0x20), just like regular 14-bit commands
	if (extendedControllerNumber - standardControllerNumber != 32) return nil;
	
	NSMutableData *result = [data mutableCopy];
	[result replaceBytesInRange:NSMakeRange(3, 2) withBytes:NULL length:0];
	return result;
}

#endif

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }

- (void)setControllerNumber:(NSUInteger)value
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	self.dataByte1 = value;
}

- (NSUInteger)controllerValue { return self.value; }

- (void)setControllerValue:(NSUInteger)value
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	self.value = value;
}

- (NSUInteger)fourteenBitValue
{
	NSUInteger MSB = ([super value] << 7) & 0x3F80;
	NSUInteger LSB = 0;
	if ([self.data length] > 3) {
		UInt8 *data = (UInt8 *)[self.data bytes];
		LSB = data[3] & 0x7F;
	}
	
	return MSB + LSB;
}

- (void)setFourteenBitValue:(NSUInteger)value
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	NSUInteger MSB = (value >> 7) & 0x7F;
	NSUInteger LSB = self.isFourteenBitCommand ? value & 0x7F : 0;
	
	[super setValue:MSB];
	if ([self.internalData length] < 4) [self.internalData increaseLengthBy:4-[self.internalData length]];
	[self.internalData replaceBytesInRange:NSMakeRange(3, 1) withBytes:&LSB length:1];
}

@dynamic channel; // MIKMIDIChannelVoiceCommand already implements a getter *and* setter for this. This keeps the compiler happy.

@end

@implementation MIKMutableMIDIControlChangeCommand

+ (BOOL)isMutable { return YES; }

#pragma mark - Properties

// One of the super classes already implements a getter *and* setter for these. @dynamic keeps the compiler happy.
@dynamic channel;
@dynamic timestamp;
@dynamic commandType;
@dynamic data;

@end