//
//  MIKMIDINoteOnCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDINoteOnCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@implementation MIKMIDINoteOnCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeNoteOn; }
+ (Class)immutableCounterpartClass; { return [MIKMIDINoteOnCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDINoteOnCommand class]; }

#pragma mark - Properties

- (NSUInteger)note { return self.dataByte1; }
- (NSUInteger)velocity { return self.value; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ note: %lu velcocity: %lu", [super description], (unsigned long)self.note, (unsigned long)self.velocity];
}

@end

@implementation MIKMutableMIDINoteOnCommand

+ (Class)immutableCounterpartClass; { return [MIKMIDINoteOnCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDINoteOnCommand mutableCounterpartClass]; }

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ note: %lu velcocity: %lu", [super description], (unsigned long)self.note, (unsigned long)self.velocity];
}

#pragma mark - Properties

- (NSUInteger)note { return self.dataByte1; }
- (void)setNote:(NSUInteger)value { self.dataByte1 = value; }
- (NSUInteger)velocity { return self.value; }
- (void)setVelocity:(NSUInteger)value { self.value = value; }

@end
