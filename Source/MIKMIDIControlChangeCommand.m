//
//  MIKMIDIControlChangeCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@implementation MIKMIDIControlChangeCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type { return type == MIKMIDICommandTypeControlChange; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIControlChangeCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIControlChangeCommand class]; }

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }

- (NSUInteger)controllerValue { return self.dataByte2; }

@end

@implementation MIKMutableMIDIControlChangeCommand

+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type; { return [MIKMIDIControlChangeCommand supportsMIDICommandType:type]; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIControlChangeCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDIControlChangeCommand mutableCounterpartClass]; }

#pragma mark - Properties

- (NSUInteger)controllerNumber { return self.dataByte1; }
- (void)setControllerNumber:(NSUInteger)value { self.dataByte1 = value; }

- (NSUInteger)controllerValue { return self.dataByte2; }
- (void)setControllerValue:(NSUInteger)value { self.dataByte2 = value; }

@end