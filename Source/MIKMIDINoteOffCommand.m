//
//  MIKMIDINoteOffCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDINoteOffCommand.h"
#import "MIKMIDIChannelVoiceCommand_SubclassMethods.h"

@interface MIKMIDINoteOffCommand ()

@property (nonatomic, readwrite) NSUInteger note;
@property (nonatomic, readwrite) NSUInteger velocity;

@end

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
- (void)setNote:(NSUInteger)value
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	self.dataByte1 = value;
}

- (NSUInteger)velocity { return self.value; }
- (void)setVelocity:(NSUInteger)value
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	self.value = value;
}

@end

@implementation MIKMutableMIDINoteOffCommand

+ (BOOL)isMutable { return YES; }

@end
