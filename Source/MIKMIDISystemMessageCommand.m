//
//  MIKMIDISystemMessageCommand.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISystemMessageCommand.h"
#import "MIKMIDICommand_SubclassMethods.h"

@implementation	MIKMIDISystemMessageCommand

+ (void)load { [super load]; [MIKMIDICommand registerSubclass:self]; }
+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type
{
	NSArray *supportedTypes = @[@(MIKMIDICommandTypeSystemMessage),
							 @(MIKMIDICommandTypeSystemTimecodeQuarterFrame),
							 @(MIKMIDICommandTypeSystemSongPositionPointer),
							 @(MIKMIDICommandTypeSystemSongSelect),
							 @(MIKMIDICommandTypeSystemTuneRequest)];
	return [supportedTypes containsObject:@(type)];
}

+ (Class)immutableCounterpartClass; { return [MIKMIDISystemMessageCommand class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDISystemMessageCommand class]; }

@end

@implementation MIKMutableMIDISystemMessageCommand

+ (Class)immutableCounterpartClass; { return [MIKMIDISystemMessageCommand immutableCounterpartClass]; }
+ (Class)mutableCounterpartClass; { return [MIKMIDISystemMessageCommand mutableCounterpartClass]; }

@end
