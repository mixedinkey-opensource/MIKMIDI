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

+ (void)registerSubclass:(Class)subclass;

+ (NSArray *)representedMIDIObjectTypes;
+ (BOOL)canInitWithObjectRef:(MIDIObjectRef)objectRef;
+ (instancetype)MIDIObjectWithObjectRef:(MIDIObjectRef)objectRef; // Returns a subclass of MIKMIDIObject (device, entity, or endpoint)
- (id)initWithObjectRef:(MIDIObjectRef)objectRef;

@property (nonatomic, readonly) MIDIObjectRef objectRef;
@property (nonatomic, readonly) MIDIUniqueID uniqueID;
@property (nonatomic, readonly, getter = isOnline) BOOL online;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *displayName;

@end
