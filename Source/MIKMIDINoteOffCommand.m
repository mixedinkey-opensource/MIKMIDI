//
//  MIKMIDINoteOffCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDINoteOffCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@implementation MIKMIDINoteOffCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeNoteOff; }
+ (Class)immutableCounterpartClass; { return [MIKMIDINoteOffCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDINoteOffCommand class]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ note: %lu velocity: %lu", [super description], (unsigned long)self.note, (unsigned long)self.velocity];
}

#pragma mark - Properties

- (NSUInteger)note { return self.dataByte1; }
- (NSUInteger)velocity { return self.dataByte2; }

@end

@implementation MIKMutableMIDINoteOffCommand

+ (Class)immutableCounterpartClass; { return [MIKMIDINoteOffCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDINoteOffCommand mutableCounterpartClass]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ note: %lu velocity: %lu", [super description], (unsigned long)self.note, (unsigned long)self.velocity];
}

#pragma mark - Properties

- (NSUInteger)note { return self.dataByte1; }
- (void)setNote:(NSUInteger)value { self.dataByte1 = value; }
- (NSUInteger)velocity { return self.dataByte2; }
- (void)setVelocity:(NSUInteger)value { self.dataByte2 = value; }

@end
