//
//  MIKMIDICommand_SubclassMethods.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDICommand.h"

@interface MIKMIDICommand ()

+ (void)registerSubclass:(Class)subclass; // Call in subclass's +load to register

+ (BOOL)supportsMIDICommandType:(MIKMIDICommandType)type;
+ (Class)immutableCounterpartClass;
+ (Class)mutableCounterpartClass;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, strong, readwrite) NSMutableData *internalData;

@end
