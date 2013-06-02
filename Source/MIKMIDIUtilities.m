//
//  MIKMIDIUtilities.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIUtilities.h"

NSString *MIKStringPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error)
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	CFStringRef result;
	OSStatus err = MIDIObjectGetStringProperty(object, propertyID, &result);
	
	if (err) {
		*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return nil;
	}
	
	return (__bridge NSString *)result;
}

SInt32 MIKIntegerPropertyFromMIDIObject(MIDIObjectRef object, CFStringRef propertyID, NSError *__autoreleasing*error)
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	SInt32 result;
	OSStatus err = MIDIObjectGetIntegerProperty(object, propertyID, &result);
	if (err) {
		*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return INT32_MIN;
	}
	return (SInt32)result;
}

MIDIObjectType MIKMIDIObjectTypeOfObject(MIDIObjectRef object, NSError *__autoreleasing*error)
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	MIDIUniqueID uniqueID = MIKIntegerPropertyFromMIDIObject(object, kMIDIPropertyUniqueID, error);
	if (uniqueID == NSNotFound) return -2;
	
	MIDIObjectRef resultObject;
	MIDIObjectType objectType;
	OSStatus err = MIDIObjectFindByUniqueID(uniqueID, &resultObject, &objectType);
	if (err) {
		*error = [NSError errorWithDomain:NSOSStatusErrorDomain code:err userInfo:nil];
		return -2;
	}

	if (resultObject != object) {
		*error = [NSError errorWithDomain:@"MIKMIDIErrorDomain" code:-1 userInfo:nil];
		return -2;
	}

	return objectType;
}