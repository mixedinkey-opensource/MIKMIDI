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
+ (BOOL)isMutable;

- (id)initWithMIDIPacket:(MIDIPacket *)packet; // Designated initializer for MIKMIDICommand

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;

@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, strong, readwrite) NSMutableData *internalData;

- (NSString *)additionalCommandDescription;

@end

#define MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION ([NSException raise:NSInternalInconsistencyException format:@"Attempt to mutate immutable %@", NSStringFromClass([self class])])
