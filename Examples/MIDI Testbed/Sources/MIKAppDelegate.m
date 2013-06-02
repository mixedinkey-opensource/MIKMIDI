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
	NSError *error = nil;
	BOOL success = [self.midiDeviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		NSMutableString *textFieldString = self.textView.textStorage.mutableString;
		for (MIKMIDIChannelVoiceCommand *command in commands) {
			if ((command.commandType | 0x0F) == MIKMIDICommandTypeSystemMessage) continue;
			[textFieldString appendFormat:@"Received command: %d %d from %@ on channel %d\n", command.dataByte1, command.dataByte2, source.name, command.channel];
			NSLog(@"Received: %@", command);
		}
	}];
	if (!success) NSLog(@"Unable to connect to input: %@", error);
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"%@'s %@ changed to: %@", object, keyPath, [object valueForKeyPath:keyPath]);
}

- (IBAction)ledCheckboxChanged:(id)sender
{
	NSButton *checkbox = (NSButton *)sender;
	
	MIKMutableMIDIControlChangeCommand *command = [[MIKMutableMIDIControlChangeCommand alloc] init];
	command.commandType = MIKMIDICommandTypeControlChange;
	command.channel = 0;
	command.controllerNumber = 0x28;
	command.controllerValue = checkbox.state == NSOnState ? 0xFF : 0x00;
	
	NSArray *destinations = [self.device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
	if (![destinations count]) return;
	MIKMIDIDestinationEndpoint *destination = destinations[0];
	NSError *error = nil;
	if (![self.midiDeviceManager sendCommands:@[command] toEndpoint:destination error:&error]) {
		NSLog(@"Unable to send command %@ to endpoint %@: %@", command, destination, error);
	}
}

- (IBAction)flash:(id)sender
{
	MIKMutableMIDIControlChangeCommand *command = [[MIKMutableMIDIControlChangeCommand alloc] init];
	command.commandType = MIKMIDICommandTypeControlChange;
	command.timestamp = [NSDate date];
	command.channel = 0;
	command.controllerNumber = 0x28;
	command.controllerValue = 0xFF;
	
	NSMutableArray *commands = [NSMutableArray arrayWithObject:command];
	
	for (NSUInteger i=0; i<10; i++) {
		command = [command mutableCopy];
		command.controllerValue = ~command.controllerValue;

		command.timestamp = [NSDate dateWithTimeInterval:0.5 sinceDate:command.timestamp];
		
		[commands addObject:command];
	}
	
	NSArray *destinations = [self.device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
	if (![destinations count]) return;
	MIKMIDIDestinationEndpoint *destination = destinations[0];
	NSError *error = nil;
	if (![self.midiDeviceManager sendCommands:commands toEndpoint:destination error:&error]) {
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

@end
