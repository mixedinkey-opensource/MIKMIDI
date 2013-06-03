//
//  ORSSoundboardViewController.m
//  MIDI Soundboard
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Open Reel Software. All rights reserved.
//

#import "ORSSoundboardViewController.h"
#import "MIKMIDI.h"

@interface ORSSoundboardViewController ()

@property (nonatomic, strong) MIKMIDIDeviceManager *deviceManager;
@property (nonatomic, strong) MIKMIDIDevice	*device;

@end

@implementation ORSSoundboardViewController

#pragma mark - Private

- (void)disconnectFromDevice:(MIKMIDIDevice *)device
{
	if (!device) return;
	NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	for (MIKMIDISourceEndpoint *source in sources) {
		[self.deviceManager disconnectInput:source];
	}
	
	self.textView.text = @"";
}

- (void)connectToDevice:(MIKMIDIDevice *)device
{
	if (!device) return;
	NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	if (![sources count]) return;
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	NSError *error = nil;
	BOOL success = [self.deviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		NSMutableString *textViewString = [self.textView.text mutableCopy];
		for (MIKMIDIChannelVoiceCommand *command in commands) {
			if ((command.commandType | 0x0F) == MIKMIDICommandTypeSystemMessage) continue;
			[textViewString appendFormat:@"Received: %@\n", command];
			NSLog(@"Received: %@", command);
		}
		self.textView.text = textViewString;
	}];
	if (!success) NSLog(@"Unable to connect to input: %@", error);
}

#pragma mark ORSAvailableDevicesTableViewControllerDelegate

- (void)availableDevicesTableViewController:(ORSAvailableDevicesTableViewController *)controller midiDeviceWasSelected:(MIKMIDIDevice *)device
{
	self.device = device;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if ([keyPath isEqualToString:@"availableDevices"]) {
		if (![self.deviceManager.availableDevices containsObject:self.device]) {
			self.device = nil;
		}
	}
}

#pragma mark - Properties

@synthesize deviceManager = _deviceManager;

- (void)setDeviceManager:(MIKMIDIDeviceManager *)deviceManager
{
	if (deviceManager != _deviceManager) {
		[_deviceManager removeObserver:self forKeyPath:@"availableDevices"];
		_deviceManager = deviceManager;
		[_deviceManager addObserver:self forKeyPath:@"availableDevices" options:NSKeyValueObservingOptionInitial context:NULL];
	}
}

- (MIKMIDIDeviceManager *)deviceManager
{
	if (!_deviceManager) {
		self.deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
	}
	return _deviceManager;
}

- (void)setDevice:(MIKMIDIDevice *)device
{
	if (device != _device) {
		[self disconnectFromDevice:_device];
		_device = device;
		[self connectToDevice:_device];
	}
}

@end
