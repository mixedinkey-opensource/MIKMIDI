//
//  MIKMIDIDevice.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIDevice.h"
#import "MIKMIDIObject_SubclassMethods.h"
#import "MIKMIDIEntity.h"
#import "MIKMIDIUtilities.h"

@interface MIKMIDIDevice ()

@property (nonatomic, strong, readwrite) NSString *manufacturer;
@property (nonatomic, strong, readwrite) NSString *model;

@property (nonatomic, strong) NSMutableArray *internalEntities;
- (void)addInternalEntitiesObject:(MIKMIDIEntity *)entity;
- (void)removeInternalEntitiesObject:(MIKMIDIEntity *)entity;

@end

@interface MIKMIDIEntity (Private)

@property (nonatomic, weak, readwrite) MIKMIDIDevice *device;

@end

@implementation MIKMIDIDevice

+ (void)load { [MIKMIDIObject registerSubclass:[self class]]; }

+ (NSArray *)representedMIDIObjectTypes; { return @[@(kMIDIObjectType_Device)]; }

- (id)initWithObjectRef:(MIDIObjectRef)objectRef
{
	self = [super initWithObjectRef:objectRef];
	if (self) {
		[self retrieveEntities];
	}
	return self;
}

#pragma mark - Public

- (NSString *)description
{
	NSMutableString *result = [NSMutableString stringWithFormat:@"%@:\r        Entities: {\r", [super description]];
	for (MIKMIDIEntity *entity in self.entities) {
		[result appendFormat:@"            %@,\r", entity];
	}
	[result appendString:@"        }"];
	return result;
}

#pragma mark - Private

- (void)retrieveEntities
{
	NSMutableArray *entities = [NSMutableArray array];
	
	ItemCount numEntities = MIDIDeviceGetNumberOfEntities(self.objectRef);
	for (ItemCount i=0; i<numEntities; i++) {
		MIDIEntityRef entityRef = MIDIDeviceGetEntity(self.objectRef, i);
		MIKMIDIEntity *entity = [MIKMIDIEntity MIDIObjectWithObjectRef:entityRef];
		if (!entity) continue;
		entity.device = self;
		[entities addObject:entity];
	}
	
	self.internalEntities = entities;
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"entities"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalEntities"];
	}
	
	return keyPaths;
}

- (NSString *)manufacturer
{
	if (!_manufacturer) {
		NSError *error = nil;
		NSString *value = MIKStringPropertyFromMIDIObject(self.objectRef, kMIDIPropertyManufacturer, &error);
		if (!value) {
			NSLog(@"Unable to get MIDI device manufacturer: %@", error);
			return nil;
		}
		self.manufacturer = value;
	}
	return _manufacturer;
}

- (NSString *)model
{
	if (!_model) {
		NSError *error = nil;
		NSString *value = MIKStringPropertyFromMIDIObject(self.objectRef, kMIDIPropertyModel, &error);
		if (!value) {
			NSLog(@"Unable to get MIDI device model: %@", error);
			return nil;
		}
		self.model = value;
	}
	return _model;
}

- (NSString *)name
{
	NSString *result = [super name];
	if (result) return result;
	return self.model;
}

- (NSString *)displayName
{
	NSString *result = [super displayName];
	if (result) return result;
	return self.model;
}

- (NSArray *)entities { return [self.internalEntities copy]; }

- (void)addInternalEntitiesObject:(MIKMIDIEntity *)entity;
{
	[self.internalEntities addObject:entity];
}

- (void)removeInternalEntitiesObject:(MIKMIDIEntity *)entity;
{
	[self.internalEntities removeObject:entity];
}

@end
