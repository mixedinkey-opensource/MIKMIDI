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
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	[self connectToSource:source];
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

- (IBAction)sendSysex:(id)sender
{
	MIKMutableMIDISystemExclusiveCommand *command = [MIKMutableMIDISystemExclusiveCommand commandForCommandType:MIKMIDICommandTypeSystemExclusive];
	command.manufacturerID = kMIKMIDISysexNonRealtimeManufacturerID;
	command.sysexChannel = kMIKMIDISysexChannelDisregard;
	command.sysexData = [NSData dataWithBytes:(UInt8[]){0x06, 0x01} length:2];
	NSLog(@"Sending idenity request command: %@", command);
	
	NSArray *destinations = [self.device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
	if (![destinations count]) return;
	MIKMIDIDestinationEndpoint *destination = destinations[0];
	NSError *error = nil;
	if (![self.midiDeviceManager sendCommands:@[command] toEndpoint:destination error:&error]) {
		NSLog(@"Unable to send command %@ to endpoint %@: %@", command, destination, error);
	}
}

#pragma mark - Devices

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
