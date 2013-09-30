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

// Notifications
NSString * const MIKMIDIDeviceWasAddedNotification = @"MIKMIDIDeviceWasAddedNotification";
NSString * const MIKMIDIDeviceWasRemovedNotification = @"MIKMIDIDeviceWasRemovedNotification";

// Notification Keys
NSString * const MIKMIDIDeviceKey = @"MIKMIDIDeviceKey";

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

- (BOOL)connectInput:(MIKMIDISourceEndpoint *)endpoint error:(NSError **)error eventHandler:(MIKMIDIEventHandlerBlock)eventHandler;
{
	OSStatus err = noErr;
	
	MIKMIDIInputPort *port = [self inputPortConnectedToEndpoint:endpoint];
	if (!port) port = [[MIKMIDIInputPort alloc] initWithClient:self.client name:endpoint.name];
	if (![port connectToSource:endpoint error:error]) return NO;
	[self addInternalConnectedInputPortsObject:port];
	[port addEventHandler:eventHandler];
	
	return err == noErr;
}

- (void)disconnectInput:(MIKMIDISourceEndpoint *)endpoint
{
	MIKMIDIInputPort *port = [self inputPortConnectedToEndpoint:endpoint];
	if (!port) return; // Not connected
	[port removeAllEventHandlers];
	[port disconnectFromSource:endpoint];
	[self removeInternalConnectedInputPortsObject:port];
}

- (BOOL)sendCommands:(NSArray *)commands toEndpoint:(MIKMIDIDestinationEndpoint *)endpoint error:(NSError **)error;
{
	return [self.outputPort sendCommands:commands toDestination:endpoint error:error];
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
		MIKMIDISourceEndpoint *source = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:sourceRef];
		if (!source) continue;
		[sources addObject:source];
	}
	self.internalVirtualSources = sources;
	
	NSMutableArray *destinations = [NSMutableArray array];
	ItemCount numDestinations = MIDIGetNumberOfDestinations();
	for (ItemCount i=0; i<numDestinations; i++) {
		MIDIEndpointRef destinationRef = MIDIGetDestination(i);
		MIKMIDISourceEndpoint *destination = [MIKMIDISourceEndpoint MIDIObjectWithObjectRef:destinationRef];
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

void MIKMIDIDeviceManagerNotifyCallback(const MIDINotification *message, void *refCon)
{
	MIKMIDIDeviceManager *self = (__bridge MIKMIDIDeviceManager *)refCon;
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	if (message->messageID == kMIDIMsgPropertyChanged) {
		MIDIObjectPropertyChangeNotification *changeNotification = (MIDIObjectPropertyChangeNotification *)message;
		if (changeNotification->objectType != kMIDIObjectType_Device) return;
		NSString *changedProperty = (__bridge NSString *)changeNotification->propertyName;
		if (![changedProperty isEqualToString:(__bridge NSString *)kMIDIPropertyOffline]) return;
		
		MIKMIDIDevice *changedObject = [MIKMIDIDevice MIDIObjectWithObjectRef:changeNotification->object];
		if (!changedObject) return;
		
		if (changedObject.isOnline && ![self.internalDevices containsObject:changedObject]) {
			[self addInternalDevicesObject:changedObject];
			[nc postNotificationName:MIKMIDIDeviceWasAddedNotification object:self userInfo:@{MIKMIDIDeviceKey : changedObject}];
		}
		if (!changedObject.isOnline) {
			[self removeInternalDevicesObject:changedObject];
			[nc postNotificationName:MIKMIDIDeviceWasRemovedNotification object:self userInfo:@{MIKMIDIDeviceKey : changedObject}];
		}
	}
	
	if (message->messageID == kMIDIMsgObjectRemoved) {
		MIDIObjectAddRemoveNotification *removeMessage = (MIDIObjectAddRemoveNotification *)message;
		if (removeMessage->childType != kMIDIObjectType_Device) return;
		MIKMIDIDevice *removedDevice = [MIKMIDIDevice MIDIObjectWithObjectRef:removeMessage->child];
		if (!removedDevice) return;
		[self removeInternalDevicesObject:removedDevice];
	}
	
	if (message->messageID == kMIDIMsgObjectAdded) {
		MIDIObjectAddRemoveNotification *addMessage = (MIDIObjectAddRemoveNotification *)message;
		if (addMessage->childType != kMIDIObjectType_Device) return;
		MIKMIDIDevice *addedDevice = [MIKMIDIDevice MIDIObjectWithObjectRef:addMessage->child];
		if (addedDevice && ![self.internalDevices containsObject:addedDevice]) {
			[self addInternalDevicesObject:addedDevice];
			[nc postNotificationName:MIKMIDIDeviceWasAddedNotification object:self userInfo:@{MIKMIDIDeviceKey : addedDevice}];
		}
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
	[self.internalVirtualDestinations addObject:destination];
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
