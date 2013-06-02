//
//  MIKMIDICommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDICommand.h"
#include <mach/mach_time.h>

@interface MIKMIDICommand ()

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, strong, readwrite) NSMutableData *internalData;

@end

@implementation MIKMIDICommand
{
	MIDIPacket *_MIDIPacket;
}

+ (instancetype)commandWithMIDIPacket:(MIDIPacket *)packet;
{
	MIKMIDICommandType commandType = packet->data[0] >> 4;
	
	Class subclass = self;
	if (commandType == MIKMIDICommandTypeControlChange) {
		subclass = [self isEqual:[MIKMutableMIDICommand class]] ? [MIKMutableMIDIControlChangeCommand class] : [MIKMIDIControlChangeCommand class];
	}
	MIKMIDICommand *result = [[subclass alloc] initWithMIDIPacket:packet];
	
	return result;
}

- (id)init
{
    self = [self initWithMIDIPacket:NULL];
    if (self) {
        self.internalData = [NSMutableData data];
    }
    return self;
}

- (id)initWithMIDIPacket:(MIDIPacket *)packet
{
	self = [super init];
	if (self) {
		self.internalData = [NSMutableData data];
		if (packet != NULL) {
			self.midiTimestamp = packet->timeStamp;
			self.internalData = [NSMutableData dataWithBytes:packet->data length:packet->length];
		}
	}
	return self;
}

- (void)dealloc
{
    if (_MIDIPacket) free(_MIDIPacket);
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ command: %d channel: %d data: %@", [super description], self.commandType, self.channel, [self.internalData subdataWithRange:NSMakeRange(1, [self.internalData length]-1)]];
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDICommand *result = [[MIKMIDICommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.internalData = [self.data mutableCopy];
	return result;
}

- (id)mutableCopy
{
	MIKMutableMIDICommand *result = [[MIKMutableMIDICommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.data = self.data;
	return result;
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"data"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalData"];
	}
	
	if ([key isEqualToString:@"commandType"] ||
		[key isEqualToString:@"channel"] ||
		[key isEqualToString:@"dataByte1"] ||
		[key isEqualToString:@"dataByte2"]) {
		keyPaths = [keyPaths setByAddingObject:@"data"];
	}
	
	if ([key isEqualToString:@"timestamp"]) {
		keyPaths = [keyPaths setByAddingObject:@"midiTimestamp"];
	}
	
	return keyPaths;
}

- (NSDate *)timestamp
{
	int64_t elapsed = self.midiTimestamp - mach_absolute_time();
	mach_timebase_info_data_t timebaseInfo;
	mach_timebase_info(&timebaseInfo);
	int64_t elapsedInNanoseconds = elapsed * timebaseInfo.numer / timebaseInfo.denom;

	NSTimeInterval elapsedInSeconds = (double)elapsedInNanoseconds / (double)NSEC_PER_SEC;
	return [NSDate dateWithTimeIntervalSinceNow:elapsedInSeconds];
}

- (UInt8)commandType
{
	if ([self.internalData length] < 1) return 0;
	UInt8 *data = (UInt8 *)[self.internalData bytes];
	return data[0] >> 4;
}

- (UInt8)channel
{
	if ([self.internalData length] < 1) return 0;
	UInt8 *data = (UInt8 *)[self.internalData bytes];
	return data[0] & 0x0F;
}

- (UInt8)dataByte1
{
	if ([self.internalData length] < 2) return 0;
	UInt8 *data = (UInt8 *)[self.internalData bytes];
	return data[1] & 0x7F;
}

- (UInt8)dataByte2
{
	if ([self.internalData length] < 3) [self.internalData increaseLengthBy:3-[self.internalData length]];
	UInt8 *data = (UInt8 *)[self.internalData bytes];
	return data[2] & 0x7F;
}

- (NSData *)data { return [self.internalData copy]; }

@end

@implementation MIKMutableMIDICommand

#pragma mark - Properties

- (void)setTimestamp:(NSDate *)date
{
	NSTimeInterval elapsedInSeconds = [date timeIntervalSinceNow];
	int64_t elapsedInNanoseconds = (int64_t)(elapsedInSeconds * (double)NSEC_PER_SEC);
	
	mach_timebase_info_data_t timebaseInfo;
	mach_timebase_info(&timebaseInfo);
	int64_t elapsed = elapsedInNanoseconds * timebaseInfo.denom / timebaseInfo.numer;
	
	self.midiTimestamp = mach_absolute_time() + elapsed;
}

- (void)setCommandType:(UInt8)commandType
{
	if ([self.internalData length] < 2) [self.internalData increaseLengthBy:1-[self.internalData length]];

	UInt8 *data = (UInt8 *)[self.internalData bytes];
	data[0] |= ((commandType << 4) & 0xF0);
}

- (void)setChannel:(UInt8)channel
{
	if ([self.internalData length] < 2) [self.internalData increaseLengthBy:1-[self.internalData length]];
	
	UInt8 *data = (UInt8 *)[self.internalData bytes];
	data[0] |= (channel & 0x0F);
}

- (void)setDataByte1:(UInt8)byte
{
	byte &= 0x7F;
	if ([self.internalData length] < 2) [self.internalData increaseLengthBy:2-[self.internalData length]];
	[self.internalData replaceBytesInRange:NSMakeRange(1, 1) withBytes:&byte length:1];
}

- (void)setDataByte2:(UInt8)byte
{
	byte &= 0x7F;
	if ([self.internalData length] < 3) [self.internalData increaseLengthBy:3-[self.internalData length]];
	[self.internalData replaceBytesInRange:NSMakeRange(2, 1) withBytes:&byte length:1];
}

- (void)setData:(NSData *)data
{
	self.internalData = [data mutableCopy];
}

@end

@implementation MIKMIDIControlChangeCommand

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIControlChangeCommand *result = [[MIKMIDIControlChangeCommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.internalData = [self.data mutableCopy];
	return result;
}

- (id)mutableCopy
{
	MIKMutableMIDIControlChangeCommand *result = [[MIKMutableMIDIControlChangeCommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.data = self.data;
	return result;
}

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }

- (NSUInteger)controllerValue { return self.dataByte2; }

@end

@implementation MIKMutableMIDIControlChangeCommand

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIControlChangeCommand *result = [[MIKMIDIControlChangeCommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.internalData = [self.data mutableCopy];
	return result;
}

- (id)mutableCopy
{
	MIKMutableMIDIControlChangeCommand *result = [[MIKMutableMIDIControlChangeCommand alloc] init];
	result.midiTimestamp = self.midiTimestamp;
	result.data = self.data;
	return result;
}

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }
- (void)setControllerNumber:(NSUInteger)value { self.dataByte1 = value; }

- (NSUInteger)controllerValue { return self.dataByte2; }
- (void)setControllerValue:(NSUInteger)value { self.dataByte2 = value; }

@end

BOOL MIKMIDIPacketListFromCommands(MIDIPacketList *inOutPacketList, ByteCount listSize, NSArray *commands)
{
	if (!listSize) listSize = sizeof(MIDIPacketList);
	MIDIPacket *currentPacket = MIDIPacketListInit(inOutPacketList);
	for (NSUInteger i=0; i<[commands count]; i++) {
		MIKMIDICommand *command = [commands objectAtIndex:i];
		currentPacket = MIDIPacketListAdd(inOutPacketList,
										  listSize,
										  currentPacket,
										  command.midiTimestamp,
										  [command.data length],
										  [command.data bytes]);
		if (!currentPacket && (i < [commands count] - 1)) return NO;
	}
	
	return YES;
}