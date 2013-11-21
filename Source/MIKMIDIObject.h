//
//  MIKMIDIObject.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/8/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MIKMIDIObject : NSObject

+ (instancetype)MIDIObjectWithObjectRef:(MIDIObjectRef)objectRef; // Returns a subclass of MIKMIDIObject (device, entity, or endpoint)
- (id)initWithObjectRef:(MIDIObjectRef)objectRef;

- (NSDictionary *)propertiesDictionary;

@property (nonatomic, readonly) MIDIObjectRef objectRef;
@property (nonatomic, readonly) MIDIUniqueID uniqueID;
@property (nonatomic, readonly, getter = isOnline) BOOL online;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *displayName;

/**
 *  Indicates whether the object is "virtual". This has slightly different meanings
 *  depending on the type of MIDI object. 
 *
 *  For MIKMIDIDevices, virtual means that the device does not represent a MIDIDeviceRef.
 *  Virtual devices can be used to wrap virtual, deviceless endpoints created
 *  e.g. by other software, some Native Instruments controllers, etc.
 *
 *  For MIKMIDIEntitys, virtual means that the entity is part of a virtual device
 *  and its endpoints are virtual endpoints.
 *
 *  For MIKMIDIEndpoints, virtual means that the endpoint is a virtual endpoint,
 *  rather than 
 *
 *  @seealso -[MIKMIDIDeviceManager virtualSources]
 *  @seealso -[MIKMIDIDeviceManager virtualDestinations]
 */
@property (nonatomic, readonly) BOOL isVirtual;

@end
