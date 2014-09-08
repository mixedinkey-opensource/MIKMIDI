//
//  MIKMIDIUtilities.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>
#import "MIKMIDIMapping.h"

NSString *MIKStringPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error);
BOOL MIKSetStringPropertyOnMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSString *string, NSError *__autoreleasing*error);

SInt32 MIKIntegerPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error);
BOOL MIKSetIntegerPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, SInt32 integerValue, NSError *__autoreleasing*error);

MIDIObjectType MIKMIDIObjectTypeOfObject(MIDIObjectRef object, NSError *__autoreleasing*error);

NSString *MIKMIDIMappingAttributeStringForInteractionType(MIKMIDIResponderType type);
MIKMIDIResponderType MIKMIDIMappingInteractionTypeForAttributeString(NSString *string);

NSInteger MIKMIDIStandardLengthOfMessageForCommandType(MIKMIDICommandType commandType);

// Subclasses of MIKMIDICommand and MIKMIDIEvent can and should use this macro to raise an exception
// when the setter for a public property is called on an immutable object.
#define MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION ([NSException raise:NSInternalInconsistencyException format:@"Attempt to mutate immutable %@", NSStringFromClass([self class])])
