//
//  MIKMIDINoteOnCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDINoteOnCommand.h"
#import "MIKMIDIChannelVoiceCommand_SubclassMethods.h"
#import "MIKMIDIUtilities.h"
#import "MIKMIDIUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDINoteOnCommand.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDINoteOnCommand.m in the Build Phases for this target
#endif

@interface MIKMIDINoteOnCommand ()

@property (nonatomic, readwrite) NSUInteger note;
@property (nonatomic, readwrite) NSUInteger velocity;

@end

@implementation MIKMIDINoteOnCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (NSArray *)supportedMIDICommandTypes { return @[@(MIKMIDICommandTypeNoteOn)]; }
+ (Class)immutableCounterpartClass; { return [MIKMIDINoteOnCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDINoteOnCommand class]; }

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

- (NSString *)additionalCommandDescription
{
	return [NSString stringWithFormat:@"%@ note: %lu velocity: %lu", [super additionalCommandDescription], (unsigned long)self.note, (unsigned long)self.velocity];
}

@end

@implementation MIKMutableMIDINoteOnCommand

+ (BOOL)isMutable { return YES; }

#pragma mark - Properties

// One of the super classes already implements a getter *and* setter for these. @dynamic keeps the compiler happy.
@dynamic timestamp;
@dynamic midiTimestamp;
@dynamic channel;
@dynamic value;
@dynamic note;
@dynamic velocity;

@end
