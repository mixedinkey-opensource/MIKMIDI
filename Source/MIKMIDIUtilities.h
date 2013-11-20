//
//  MIKMIDIUtilities.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

NSString *MIKStringPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error);
BOOL MIKSetStringPropertyOnMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSString *string, NSError *__autoreleasing*error);

SInt32 MIKIntegerPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error);
BOOL MIKSetIntegerPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, SInt32 integerValue, NSError *__autoreleasing*error);

MIDIObjectType MIKMIDIObjectTypeOfObject(MIDIObjectRef object, NSError *__autoreleasing*error);