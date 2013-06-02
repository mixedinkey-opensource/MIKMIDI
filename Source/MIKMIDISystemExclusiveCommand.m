//
//  MIKMIDISystemExclusiveCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISystemExclusiveCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@interface MIKMIDISystemExclusiveCommand ()

@property (nonatomic, readwrite) UInt32 manufacturerID;

@end

@implementation MIKMIDISystemExclusiveCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeSystemExclusive; }
+ (Class)immutableCounterpartClass; { return [MIKMIDISystemExclusiveCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDISystemExclusiveCommand class]; }

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *result = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"sysexData"]) {
		result = [result setByAddingObject:@"internalData"];
	}
	
	return result;
}

- (NSData *)sysexData
{
	return [self.internalData subdataWithRange:NSMakeRange(2, [self.internalData length]-2)];
}

@end

@implementation MIKMutableMIDISystemExclusiveCommand

+ (Class)immutableCounterpartClass; { return [MIKMIDISystemExclusiveCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDISystemExclusiveCommand mutableCounterpartClass]; }

#pragma mark - Properties

- (void)setSysexData:(NSData *)sysexData
{
	[self.internalData replaceBytesInRange:NSMakeRange(2, [self.internalData length]-2) withBytes:[sysexData bytes] length:[sysexData length]];
}

@end
