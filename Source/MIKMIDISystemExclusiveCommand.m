//
//  MIKMIDISystemExclusiveCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISystemExclusiveCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

#if !__has_feature(objc_arc)
#error MIKMIDISystemExclusiveCommand.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDISystemExclusiveCommand.m in the Build Phases for this target
#endif

@interface MIKMIDISystemExclusiveCommand ()

@property (nonatomic, readwrite) UInt32 manufacturerID;
@property (nonatomic, readwrite) UInt8 sysexChannel;
@property (nonatomic, strong, readwrite) NSData *sysexData;

@end

@implementation MIKMIDISystemExclusiveCommand
{
	BOOL _has3ByteManufacturerID;
}

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeSystemExclusive; }
+ (Class)immutableCounterpartClass; { return [MIKMIDISystemExclusiveCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDISystemExclusiveCommand class]; }

#pragma mark - Private

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *result = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sysexData"]) {
		result = [result setByAddingObject:@"internalData"];
	}
	
	return result;
}

- (id)initWithMIDIPacket:(MIDIPacket *)packet {
    self = [super initWithMIDIPacket:packet];
    UInt8 firstByte = self.dataByte1;
    if (firstByte == 0) {
        _has3ByteManufacturerID = YES;
    }
    return self;
}

- (UInt32)manufacturerID
{
    if ([self.internalData length] < 2) return 0;
    
    NSUInteger manufacturerIDLocation = _has3ByteManufacturerID ? 2 : 1;
    NSUInteger manufacturerIDLength = _has3ByteManufacturerID ? 2 : 1;
    NSData *idData = [self.internalData subdataWithRange:NSMakeRange(manufacturerIDLocation, manufacturerIDLength)];
    return *(UInt32 *)[idData bytes];
}

- (void)setManufacturerID:(UInt32)manufacturerID
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	NSUInteger numExistingBytes = _has3ByteManufacturerID ? 3 : 1;
	NSUInteger numNewBytes = (manufacturerID & 0xFFFF00) != 0 ? 3 : 1;
	UInt8 manufacturerIDBytes[3] = {(manufacturerID >> 2) & 0x7F, (manufacturerID >> 1) & 0x7F, manufacturerID & 0x7F};
	if ([self.internalData length] < numNewBytes+1) [self.internalData increaseLengthBy:numNewBytes-[self.internalData length]+1];
	
	UInt8 *replacementBytes = manufacturerIDBytes + 3 - numNewBytes;
	[self.internalData replaceBytesInRange:NSMakeRange(1, numExistingBytes) withBytes:replacementBytes length:numNewBytes];
	
	_has3ByteManufacturerID = (numNewBytes == 3);
}

- (UInt8)modelID
{
    NSUInteger modelIDLocation = _has3ByteManufacturerID ? 4 : 2;
    if ([self.internalData length] <= modelIDLocation) return 0;
    
    NSData *modelIDData = [self.internalData subdataWithRange:NSMakeRange(modelIDLocation, 1)];
    return *(UInt8 *)[modelIDData bytes];
}

- (void)setModelID:(UInt8)modelID {
    NSUInteger modelIDLocation = _has3ByteManufacturerID ? 4 : 2;
    NSMutableData *internalData = self.internalData;
    if ([internalData length] <= modelIDLocation) [internalData increaseLengthBy:modelIDLocation - [internalData length]+1];
    [internalData replaceBytesInRange:NSMakeRange(modelIDLocation, 1) withBytes:&modelID length:1];
}

- (UInt8)sysexChannel
{
	if ([self.sysexData length] < 1) return 0;
	
	NSData *sysexChannelData = [self.sysexData subdataWithRange:NSMakeRange(0, 1)];
	return *(UInt8 *)[sysexChannelData bytes];
}

- (void)setSysexChannel:(UInt8)sysexChannel
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	NSUInteger sysexChannelLocation = _has3ByteManufacturerID ? 4 : 2;
	NSUInteger requiredLength = sysexChannelLocation+1;
	[self.internalData setLength:requiredLength];
	
	[self.internalData replaceBytesInRange:NSMakeRange(sysexChannelLocation, 1) withBytes:&sysexChannel length:1];
}

- (NSData *)sysexData
{
	NSUInteger sysexStartLocation = _has3ByteManufacturerID ? 5 : 3;
	return [self.internalData subdataWithRange:NSMakeRange(sysexStartLocation, [self.internalData length]-sysexStartLocation-1)];
}

- (void)setSysexData:(NSData *)sysexData
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	NSUInteger sysexStartLocation = _has3ByteManufacturerID ? 5 : 3;
	
	NSRange destinationRange = NSMakeRange(sysexStartLocation, [self.internalData length] - sysexStartLocation);
	[self.internalData replaceBytesInRange:destinationRange withBytes:[sysexData bytes] length:[sysexData length]];
}

- (NSData *)data
{
	NSMutableData *result = [[super data] mutableCopy];
    
    UInt8 lastByte;
    [result getBytes:&lastByte range:NSMakeRange(result.length-1, 1)];
    if (lastByte != kMIKMIDISysexEndDelimiter) {
        [result appendBytes:&(UInt8){kMIKMIDISysexEndDelimiter} length:1];
    }
	return result;
}

- (void)setData:(NSData *)data
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	if (![data length]) return [self setInternalData:[data mutableCopy]];
	
	UInt8 *bytes = (UInt8 *)[data bytes];
	UInt8 lastByte = bytes[[data length]-1];
	if (lastByte == kMIKMIDISysexEndDelimiter) {
		data = [data subdataWithRange:NSMakeRange(0, [data length]-1)];
	}
	
	self.internalData = [data mutableCopy];
}

@end

@implementation MIKMutableMIDISystemExclusiveCommand

+ (BOOL)isMutable { return YES; }

@end
