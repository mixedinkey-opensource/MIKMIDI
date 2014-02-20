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
@property (nonatomic, strong) NSMapTable *connectionTokensForSources;

@end

@implementation MIKAppDelegate

- (id)init
{
    self = [super init];
    if (self) {
        self.connectionTokensForSources = [NSMapTable strongToStrongObjectsMapTable];
    }
    return self;
}

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

#pragma mark - Connections

- (void)connectToSource:(MIKMIDISourceEndpoint *)source
{
	NSError *error = nil;
	id connectionToken = [self.midiDeviceManager connectInput:source error:&error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		for (MIKMIDIChannelVoiceCommand *command in commands) { [self handleMIDICommand:command]; }
	}];
	if (!connectionToken) {
		NSLog(@"Unable to connect to input: %@", error);
		return;
	}
	[self.connectionTokensForSources setObject:connectionToken forKey:source];
}

- (void)disconnectFromSource:(MIKMIDISourceEndpoint *)source
{
	if (!source) return;
	id token = [self.connectionTokensForSources objectForKey:source];
	if (!token) return;
	[self.midiDeviceManager disconnectInput:source forConnectionToken:token];
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

- (void)disconnectFromDevice:(MIKMIDIDevice *)device
{
	if (!device) return;
	NSArray *sources = [device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	for (MIKMIDISourceEndpoint *source in sources) {
		[self disconnectFromSource:source];
	}
}

- (void)handleMIDICommand:(MIKMIDICommand *)command
{
	NSMutableString *textFieldString = self.textView.textStorage.mutableString;
	[textFieldString appendFormat:@"Received: %@\n", command];
    [self.textView scrollToEndOfDocument:self];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	NSLog(@"%@'s %@ changed to: %@", object, keyPath, [object valueForKeyPath:keyPath]);
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

#pragma mark - Command Execution

- (IBAction)clearOutput:(id)sender 
{
    [self.textView setString:@""];
}

- (IBAction)sendSysex:(id)sender
{
    NSComboBox *comboBox = self.commandComboBox;
    NSString *commandString = [[comboBox stringValue] stringByReplacingOccurrencesOfString:@" " withString:@""];
    if (!commandString || commandString.length == 0) {
        return;
    }
    
    struct MIDIPacket packet;
    packet.timeStamp = mach_absolute_time();
    packet.length = commandString.length / 2;
    
    char byte_chars[3] = {'\0','\0','\0'};
    for (int i = 0; i < packet.length; i++) {
        byte_chars[0] = [commandString characterAtIndex:i*2];
        byte_chars[1] = [commandString characterAtIndex:i*2+1];
        packet.data[i] = strtol(byte_chars, NULL, 16);;
    }

    MIKMIDICommand *command = [MIKMIDICommand commandWithMIDIPacket:&packet];
	NSLog(@"Sending idenity request command: %@", command);
	
	NSArray *destinations = [self.device.entities valueForKeyPath:@"@unionOfArrays.destinations"];
	if (![destinations count]) return;
	for (MIKMIDIDestinationEndpoint *destination in destinations) {
        NSError *error = nil;
        if (![self.midiDeviceManager sendCommands:@[command] toEndpoint:destination error:&error]) {
            NSLog(@"Unable to send command %@ to endpoint %@: %@", command, destination, error);
        }
    }
}

@synthesize availableCommands = _availableCommands;
- (NSArray *)availableCommands 
{
    if (_availableCommands == nil) {
        MIKMIDISystemExclusiveCommand *identityRequest = [MIKMIDISystemExclusiveCommand identityRequestCommand];
        NSString *identityRequestString = [NSString stringWithFormat:@"%@", identityRequest.data];
        identityRequestString = [identityRequestString substringWithRange:NSMakeRange(1, identityRequestString.length-2)];
        _availableCommands = @[
                               @{@"name": @"Identity Request",
                                 @"value": identityRequestString}
                               ];
    }
    return _availableCommands;
}

- (IBAction)commandTextFieldDidSelect:(id)sender 
{
    NSComboBox *comboBox = (NSComboBox *)sender;
    NSString *selectedValue = [comboBox objectValueOfSelectedItem];
    NSArray *availableCommands = [self availableCommands];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:[NSString stringWithFormat:@"name=\"%@\"", selectedValue]];
    NSDictionary *selectedObject = [[availableCommands filteredArrayUsingPredicate:predicate] firstObject];
    if (selectedObject) {
        [comboBox setStringValue:selectedObject[@"value"]];
    }
    [self sendSysex:sender];
}

@end
