//
//  MIKAppDelegate.m
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKAppDelegate.h"
#import "MIKMIDI.h"
#import <mach/mach.h>
#import <mach/mach_time.h>

@interface MIKAppDelegate ()

@property (nonatomic, strong) MIKMIDIDeviceManager *midiDeviceManager;

@end

@implementation MIKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	self.midiDeviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
	[self.midiDeviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.midiDeviceManager addObserver:self forKeyPath:@"virtualSources" options:NSKeyValueObservingOptionInitial context:NULL];
	[self.midiDeviceManager addObserver:self forKeyPath:@"virtualDestinations" options:NSKeyValueObservingOptionInitial context:NULL];
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
	[self.midiDeviceManager removeObserver:self forKeyPath:@"availableDevices"];
	[self.midiDeviceManager removeObserver:self forKeyPath:@"virtualSources"];
	[self.midiDeviceManager removeObserver:self forKeyPath:@"virtualDestinations"];
}

- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source
{
	if (!source) return;
	[self.midiDeviceManager disconnectInput:source];
}

- (void)connectToSource:(MIKMIDISourceEndpoint *)source
{
	NSError *error = nil;
	BOOL success = [self.midiDeviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		for (MIKMIDIChannelVoiceCommand *command in commands) { [self handleMIDICommand:command]; }
	}];
	if (!success) NSLog(@"Unable to connect to input: %@", error);
}

- (void)disconnectFromDevice:(MIKMIDIDevice *)device
{
	if (!device) return;
	NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	for (MIKMIDISourceEndpoint *source in sources) {
		[self.midiDeviceManager disconnectInput:source];
	}
}

- (void)connectToDevice:(MIKMIDIDevice *)device
{
	if (!device) return;
	NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	if (![sources count]) return;
    for (MIKMIDISourceEndpoint *source in sources) {
        [self connectToSource:source];
    }
}

- (void)handleMIDICommand:(MIKMIDICommand *)command
{
	NSMutableString *textFieldString = self.textView.textStorage.mutableString;
	[textFieldString appendFormat:@"Received: %@\n", command];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"%@'s %@ changed to: %@", object, keyPath, [object valueForKeyPath:keyPath]);
}

- (IBAction)clearOutput:(id)sender {
    [self.textView setString:@""];
}

- (IBAction)sendSysex:(id)sender
{
	MIKMutableMIDISystemExclusiveCommand *command = [MIKMutableMIDISystemExclusiveCommand commandForCommandType:MIKMIDICommandTypeSystemExclusive];
	command.manufacturerID = kMIKMIDISysexNonRealtimeManufacturerID;
	command.sysexChannel = kMIKMIDISysexChannelDisregard;
	command.sysexData = [NSData dataWithBytes:(UInt8[]){0x06, 0x01} length:2];
	NSLog(@"Sending idenity request command: %@", command);
	
	NSArray *destinations = [self.device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
	if (![destinations count]) return;
	for (MIKMIDIDestinationEndpoint *destination in destinations) {
        NSError *error = nil;
        NSLog(@"Sending identity request to: %@", destination);
        if (![self.midiDeviceManager sendCommands:@[command] toEndpoint:destination error:&error]) {
            NSLog(@"Unable to send command %@ to endpoint %@: %@", command, destination, error);
        }
    }
}

#pragma mark - Devices

+ (NSSet *)keyPathsForValuesAffectingAvailableDevices
{
	return [NSSet setWithObject:@"midiDeviceManager.availableDevices"];
}

- (NSArray *)availableDevices
{
	NSArray *regularDevices = [self.midiDeviceManager availableDevices];
	NSMutableArray *result = [regularDevices mutableCopy];
	
	NSMutableSet *endpointsInDevices = [NSMutableSet set];
	for (MIKMIDIDevice *device in regularDevices) {
		NSSet *sources = [NSSet setWithArray:[device.entities valueForKeyPath:@"@distinctUnionOfArrays.sources"]];
		NSSet *destinations = [NSSet setWithArray:[device.entities valueForKeyPath:@"@distinctUnionOfArrays.destinations"]];
		[endpointsInDevices unionSet:sources];
		[endpointsInDevices unionSet:destinations];
	}
	
	NSMutableSet *devicelessSources = [NSMutableSet setWithArray:self.midiDeviceManager.virtualSources];
	NSMutableSet *devicelessDestinations = [NSMutableSet setWithArray:self.midiDeviceManager.virtualDestinations];
	[devicelessSources minusSet:endpointsInDevices];
	[devicelessDestinations minusSet:endpointsInDevices];
	
	// Now we need to try to associate each source with its corresponding destination on the same device
	NSMapTable *destinationToSourceMap = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
	NSMapTable *deviceNamesBySource = [NSMapTable mapTableWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory];
	NSCharacterSet *whitespace = [NSCharacterSet whitespaceCharacterSet];
	for (MIKMIDIEndpoint *source in devicelessSources) {
		NSMutableArray *sourceNameComponents = [[source.name componentsSeparatedByCharactersInSet:whitespace] mutableCopy];
		[sourceNameComponents removeLastObject];
		for (MIKMIDIEndpoint *destination in devicelessDestinations) {
			NSMutableArray *destinationNameComponents = [[destination.name componentsSeparatedByCharactersInSet:whitespace] mutableCopy];
			[destinationNameComponents removeLastObject];
			
			if ([sourceNameComponents isEqualToArray:destinationNameComponents]) {
				// Source and destination match
				[destinationToSourceMap setObject:destination forKey:source];

				NSString *deviceName = [sourceNameComponents componentsJoinedByString:@" "];
				[deviceNamesBySource setObject:deviceName forKey:source];
				break;
			}
		}
	}
	
	for (MIKMIDIEndpoint *source in destinationToSourceMap) {
		MIKMIDIEndpoint *destination = [destinationToSourceMap objectForKey:source];
		[devicelessSources removeObject:source];
		[devicelessDestinations removeObject:destination];
		
		MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[source, destination]];
		device.name = [deviceNamesBySource objectForKey:source];
	 	if (device) [result addObject:device];
	}
	for (MIKMIDIEndpoint *endpoint in devicelessSources) {
		MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[endpoint]];
	 	if (device) [result addObject:device];
	}
	for (MIKMIDIEndpoint *endpoint in devicelessSources) {
		MIKMIDIDevice *device = [MIKMIDIDevice deviceWithVirtualEndpoints:@[endpoint]];
	 	if (device) [result addObject:device];
	}
	
	return result;
}

- (void)setDevice:(MIKMIDIDevice *)device
{
	if (device != _device) {
		[self disconnectFromDevice:_device];
		_device = device;
		[self connectToDevice:_device];
	}
}

- (void)setSource:(MIKMIDISourceEndpoint *)source
{
	if (source != _source) {
		[self disconnectFromSource:_source];
		_source = source;
		[self connectToSource:_source];
	}
}

@end
