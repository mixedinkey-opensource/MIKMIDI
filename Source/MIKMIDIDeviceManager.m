//
//  MIKMIDIDeviceManager.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIDeviceManager.h"
#import <CoreMIDI/CoreMIDI.h>
#import "MIKMIDIDevice.h"
#import "MIKMIDISourceEndpoint.h"
#import "MIKMIDIDestinationEndpoint.h"
#import "MIKMIDIInputPort.h"
#import "MIKMIDIOutputPort.h"
#import "MIKMIDIClientSourceEndpoint.h"

#if !__has_feature(objc_arc)
#error MIKMIDIDeviceManager.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIDeviceManager.m in the Build Phases for this target
#endif

// Notifications
NSString * const MIKMIDIDeviceWasAddedNotification = @"MIKMIDIDeviceWasAddedNotification";
NSString * const MIKMIDIDeviceWasRemovedNotification = @"MIKMIDIDeviceWasRemovedNotification";
NSString * const MIKMIDIVirtualEndpointWasAddedNotification = @"MIKMIDIVirtualEndpointWasAddedNotification";
NSString * const MIKMIDIVirtualEndpointWasRemovedNotification = @"MIKMIDIVirtualEndpointWasRemovedNotification";


// Notification Keys
NSString * const MIKMIDIDeviceKey = @"MIKMIDIDeviceKey";
NSString * const MIKMIDIEndpointKey = @"MIKMIDIEndpointKey";

static MIKMIDIDeviceManager *sharedDeviceManager;

@interface MIKMIDIDeviceManager ()

@property (nonatomic) MIDIClientRef client;
@property (nonatomic, strong) NSMutableArray *internalDevices;
- (void)addInternalDevicesObject:(MIKMIDIDevice *)device;
- (void)removeInternalDevicesObject:(MIKMIDIDevice *)device;

@property (nonatomic, strong) NSMutableArray *internalVirtualSources;
- (void)addInternalVirtualSourcesObject:(MIKMIDISourceEndpoint *)source;
- (void)removeInternalVirtualSourcesObject:(MIKMIDISourceEndpoint *)source;

@property (nonatomic, strong) NSMutableArray *internalVirtualDestinations;
- (void)addInternalVirtualDestinationsObject:(MIKMIDIDestinationEndpoint *)destination;
- (void)removeInternalVirtualDestinationsObject:(MIKMIDIDestinationEndpoint *)destination;

@property (nonatomic, strong) NSMutableSet *internalConnectedInputPorts;
@property (nonatomic, strong) MIKMIDIOutputPort *outputPort;

@end

@implementation MIKMIDIDeviceManager

+ (instancetype)sharedDeviceManager;
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedDeviceManager = [(MIKMIDIDeviceManager *)[super allocWithZone:NULL] init];
	});
	return sharedDeviceManager;
}

- (id)init
{
	if (self == sharedDeviceManager) return sharedDeviceManager;
	
    self = [super init];
    if (self) {
		[self createClient];
        [self retrieveAvailableDevices];
		[self retrieveVirtualEndpoints];
		self.internalConnectedInputPorts = [[NSMutableSet alloc] init];
    }
    return self;
}

+ (id)allocWithZone:(NSZone *)zone
{
	return [self sharedDeviceManager];
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;
}

#pragma mark - Public

- (id)connectInput:(MIKMIDISourceEndpoint *)endpoint error:(NSError **)error eventHandler:(MIKMIDIEventHandlerBlock)eventHandler
{
	MIKMIDIInputPort *port = [self inputPortConnectedToEndpoint:endpoint];
	if (!port) {
		port = [[MIKMIDIInputPort alloc] initWithClient:self.client name:endpoint.name];
		if (![port connectToSource:endpoint error:error]) return nil;
	}
	
	[self addInternalConnectedInputPortsObject:port];
	return [port addEventHandler:eventHandler];
}

- (void)disconnectInput:(MIKMIDISourceEndpoint *)endpoint forConnectionToken:(id)connectionToken
{
	MIKMIDIInputPort *port = [self inputPortConnectedToEndpoint:endpoint];
	if (!port) return; // Not connected
	
	[port removeEventHandlerForToken:connectionToken];
	if (![[port eventHandlers] count]) {
		[port disconnectFromSource:endpoint];
		[self removeInternalConnectedInputPortsObject:port];
	}
}

- (BOOL)sendCommands:(NSArray *)commands toEndpoint:(MIKMIDIDestinationEndpoint *)endpoint error:(NSError **)error;
{
	return [self.outputPort sendCommands:commands toDestination:endpoint error:error];
}


- (BOOL)sendCommands:(NSArray *)commands toVirtualEndpoint:(MIKMIDIClientSourceEndpoint *)endpoint error:(NSError **)error
{
    return [endpoint sendCommands:commands error:error];
}


#pragma mark - Private

- (void)createClient
{
	MIDIClientRef client;
	OSStatus error = MIDIClientCreate(CFSTR("MIKMIDIDeviceManager"), MIKMIDIDeviceManagerNotifyCallback, (__bridge void *)self, &client);
	if (error != noErr) { NSLog(@"Unable to create MIDI client"); return; }
	self.client = client;
}

- (void)retrieveAvailableDevices
{
	ItemCount numDevices = MIDIGetNumberOfDevices();
	NSMutableArray *devices = [NSMutableArray arrayWithCapacity:numDevices];
	
	for (ItemCount i=0; i<numDevices; i++) {
		MIDIDeviceRef deviceRef = MIDIGetDevice(i);
		MIKMIDIDevice *device = [MIKMIDIDevice MIDIObjectWithObjectRef:deviceRef];
		if (!device || !device.isOnline) continue;
		[devices addObject:device];
	}
	
	self.internalDevices = devices;
}

- (void)retrieveVirtualEndpoints
{
	NSMutableArray *sources = [NSMutableArray array];
	ItemCount numSources = MIDIGetNumberOfSources();
	for (ItemCount i=0; i<numSources; i++) {
		MIDIEndpointRef sourceRef = MIDIGetSource(i);
		MIKMIDIEndpoint *source = [MIKMIDIEndpoint MIDIObjectWithObjectRef:sourceRef];
		if (!source) continue;
		[sources addObject:source];
	}
	self.internalVirtualSources = sources;
	
	NSMutableArray *destinations = [NSMutableArray array];
	ItemCount numDestinations = MIDIGetNumberOfDestinations();
	for (ItemCount i=0; i<numDestinations; i++) {
		MIDIEndpointRef destinationRef = MIDIGetDestination(i);
		MIKMIDIEndpoint *destination = [MIKMIDIEndpoint MIDIObjectWithObjectRef:destinationRef];
		if (!destination) continue;
		[destinations addObject:destination];
	}
	self.internalVirtualDestinations = destinations;
}

- (MIKMIDIInputPort *)inputPortConnectedToEndpoint:(MIKMIDIEndpoint *)endpoint
{
	for (MIKMIDIInputPort *port in self.internalConnectedInputPorts) {
		if (![port isKindOfClass:[MIKMIDIInputPort class]]) continue;
		if ([port.connectedSources containsObject:endpoint]) return port;
	}
	return nil;
}

#pragma mark - Callbacks

- (void)handleMIDIObjectPropertyChangeNotification:(MIDIObjectPropertyChangeNotification *)notification
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	NSString *changedProperty = (__bridge NSString *)notification->propertyName;
	
	switch (notification->objectType) {
		case kMIDIObjectType_Device: {
			
			if (![changedProperty isEqualToString:(__bridge NSString *)kMIDIPropertyOffline]) break;
			
			MIKMIDIDevice *changedObject = [MIKMIDIDevice MIDIObjectWithObjectRef:notification->object];
			if (!changedObject) break;
			
			if (changedObject.isOnline && ![self.internalDevices containsObject:changedObject]) {
				[self addInternalDevicesObject:changedObject];
				[nc postNotificationName:MIKMIDIDeviceWasAddedNotification object:self userInfo:@{MIKMIDIDeviceKey : changedObject}];
			}
			if (!changedObject.isOnline) {
				[self removeInternalDevicesObject:changedObject];
				[nc postNotificationName:MIKMIDIDeviceWasRemovedNotification object:self userInfo:@{MIKMIDIDeviceKey : changedObject}];
			}
		}
			break;
		case kMIDIObjectType_Source: {
			
			if (![changedProperty isEqualToString:(__bridge NSString *)kMIDIPropertyPrivate]) break;
			
			MIKMIDISourceEndpoint *changedObject = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:notification->object];
			if (!changedObject) break;
			
			if (!changedObject.isPrivate && ![self.internalVirtualSources containsObject:changedObject]) {
				[self addInternalVirtualSourcesObject:changedObject];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasAddedNotification object:self userInfo:@{MIKMIDIEndpointKey : changedObject}];
			}
			if (changedObject.isPrivate) {
				[self removeInternalVirtualSourcesObject:changedObject];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasRemovedNotification object:self userInfo:@{MIKMIDIEndpointKey : changedObject}];
			}
		}
			break;
		case kMIDIObjectType_Destination: {
			
			if (![changedProperty isEqualToString:(__bridge NSString *)kMIDIPropertyPrivate]) break;
			
			MIKMIDIDestinationEndpoint *changedObject = [MIKMIDIDestinationEndpoint MIDIObjectWithObjectRef:notification->object];
			if (!changedObject) break;
			
			if (!changedObject.isPrivate && ![self.internalVirtualDestinations containsObject:changedObject]) {
				[self addInternalVirtualDestinationsObject:changedObject];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasAddedNotification object:self userInfo:@{MIKMIDIEndpointKey : changedObject}];
			}
			if (changedObject.isPrivate) {
				[self removeInternalVirtualDestinationsObject:changedObject];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasRemovedNotification object:self userInfo:@{MIKMIDIEndpointKey : changedObject}];
			}
		}
			break;
		default:
			break;
	}
}

- (void)handleMIDIObjectRemoveNotification:(MIDIObjectAddRemoveNotification *)notification
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	switch (notification->childType) {
		case kMIDIObjectType_Device: {
			MIKMIDIDevice *removedDevice = [MIKMIDIDevice MIDIObjectWithObjectRef:notification->child];
			if (!removedDevice) break;
			[self removeInternalDevicesObject:removedDevice];
		}
			break;
		case kMIDIObjectType_Source: {
			MIKMIDISourceEndpoint *removedSource = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:notification->child];
			if (!removedSource) {
				// Sometimes that fails even though the MIDIObjectRef is for an object we already have an instance for
				// FIXME: It might be better to have MIKMIDIObject maintain a table of instances and return an existing
				// instance if a known object ref is passed into MIDIObjectWithObjectRef:
				for (MIKMIDISourceEndpoint *source in self.virtualSources) {
					if (source.objectRef == notification->child) {
						removedSource = source;
						break;
					}
				}
			}
			if (!removedSource) break;
			[self removeInternalVirtualSourcesObject:removedSource];
			[nc postNotificationName:MIKMIDIVirtualEndpointWasRemovedNotification object:self userInfo:@{MIKMIDIEndpointKey : removedSource}];
		}
			break;
		case kMIDIObjectType_Destination: {
			MIKMIDIDestinationEndpoint *removedDestination = [MIKMIDIDestinationEndpoint MIDIObjectWithObjectRef:notification->child];
			if (!removedDestination) {
				// Sometimes that fails even though the MIDIObjectRef is for an object we already have an instance for
				for (MIKMIDIDestinationEndpoint *destination in self.virtualDestinations) {
					if (destination.objectRef == notification->child) {
						removedDestination = destination;
						break;
					}
				}
			}
			if (!removedDestination) break;
			[self removeInternalVirtualDestinationsObject:removedDestination];
			[nc postNotificationName:MIKMIDIVirtualEndpointWasRemovedNotification object:self userInfo:@{MIKMIDIEndpointKey : removedDestination}];
		}
			break;
		default:
			break;
	}
}

- (void)handleMIDIObjectAddNotification:(MIDIObjectAddRemoveNotification *)notification
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	switch (notification->childType) {
		case kMIDIObjectType_Device: {
			MIKMIDIDevice *addedDevice = [MIKMIDIDevice MIDIObjectWithObjectRef:notification->child];
			if (addedDevice && ![self.internalDevices containsObject:addedDevice]) {
				[self addInternalDevicesObject:addedDevice];
				[nc postNotificationName:MIKMIDIDeviceWasAddedNotification object:self userInfo:@{MIKMIDIDeviceKey : addedDevice}];
			}
		}
			break;
		case kMIDIObjectType_Source: {
			MIKMIDISourceEndpoint *addedSource = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:notification->child];
			if (addedSource && ![self.internalVirtualSources containsObject:addedSource]) {
				[self addInternalVirtualSourcesObject:addedSource];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasAddedNotification object:self userInfo:@{MIKMIDIEndpointKey : addedSource}];
			}
		}
			break;
		case kMIDIObjectType_Destination: {
			MIKMIDIDestinationEndpoint *addedDestination = [MIKMIDIDestinationEndpoint MIDIObjectWithObjectRef:notification->child];
			if (addedDestination && ![self.internalVirtualDestinations containsObject:addedDestination]) {
				[self addInternalVirtualDestinationsObject:addedDestination];
				[nc postNotificationName:MIKMIDIVirtualEndpointWasAddedNotification object:self userInfo:@{MIKMIDIEndpointKey : addedDestination}];
			}
		}
			break;
		default:
			break;
	}
}

void MIKMIDIDeviceManagerNotifyCallback(const MIDINotification *message, void *refCon)
{
	MIKMIDIDeviceManager *self = (__bridge MIKMIDIDeviceManager *)refCon;
	
	switch (message->messageID) {
		case kMIDIMsgPropertyChanged:
			[self handleMIDIObjectPropertyChangeNotification:(MIDIObjectPropertyChangeNotification *)message];
			break;
		case kMIDIMsgObjectRemoved:
			[self handleMIDIObjectRemoveNotification:(MIDIObjectAddRemoveNotification *)message];
			break;
		case kMIDIMsgObjectAdded:
			[self handleMIDIObjectAddNotification:(MIDIObjectAddRemoveNotification *)message];
			break;
		default:
			break;
	}
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"availableDevices"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalDevices"];
	}
	
	if ([key isEqualToString:@"virtualSources"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalVirtualSources"];
	}
	
	if ([key isEqualToString:@"virtualDestinations"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalVirtualDestinations"];
	}
	
	if ([key isEqualToString:@"connectedInputSources"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalConnectedInputPorts"];
	}
	
	return keyPaths;
}

- (NSArray *)availableDevices { return [self.internalDevices copy]; }

- (void)addInternalDevicesObject:(MIKMIDIDevice *)device;
{
	[self.internalDevices addObject:device];
}

- (void)removeInternalDevicesObject:(MIKMIDIDevice *)device;
{
	[self.internalDevices removeObject:device];
}

- (NSArray *)virtualSources { return [self.internalVirtualSources copy]; }

- (void)addInternalVirtualSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalVirtualSources addObject:source];
}

- (void)removeInternalVirtualSourcesObject:(MIKMIDISourceEndpoint *)source
{
	[self.internalVirtualSources removeObject:source];
}

- (NSArray *)virtualDestinations { return [self.internalVirtualDestinations copy]; }

- (void)addInternalVirtualDestinationsObject:(MIKMIDIDestinationEndpoint *)destination
{
	[self.internalVirtualDestinations addObject:destination];
}

- (void)removeInternalVirtualDestinationsObject:(MIKMIDIDestinationEndpoint *)destination
{
	[self.internalVirtualDestinations removeObject:destination];
}

- (NSArray *)connectedInputSources
{
	NSMutableSet *result = [NSMutableSet set];
	for (MIKMIDIInputPort *port in self.internalConnectedInputPorts) {
		NSArray *connectedSources = port.connectedSources;
		if (![connectedSources count]) continue;
		[result addObjectsFromArray:connectedSources];
	}
	return [result allObjects];
}

- (void)addInternalConnectedInputPortsObject:(MIKMIDIInputPort *)port
{
	[_internalConnectedInputPorts addObject:port];
}

- (void)removeInternalConnectedInputPortsObject:(MIKMIDIInputPort *)port
{
	[_internalConnectedInputPorts removeObject:port];
}

- (MIKMIDIOutputPort *)outputPort
{
	if (!_outputPort) {
		self.outputPort = [[MIKMIDIOutputPort alloc] initWithClient:self.client name:@"OutputPort"];
	}
	return _outputPort;
}

@end
