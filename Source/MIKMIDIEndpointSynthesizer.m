//
//  MIKMIDIEndpointSynthesizer.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 5/27/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#if !TARGET_OS_IPHONE

#import "MIKMIDIEndpointSynthesizer.h"
#import <AudioToolbox/AudioToolbox.h>
#import <MIKMIDI/MIKMIDI.h>
#import "MIKMIDIClientDestinationEndpoint.h"

@interface MIKMIDIEndpointSynthesizer ()

@property (nonatomic, strong, readwrite) MIKMIDIEndpoint *endpoint;
@property (nonatomic, strong) id connectionToken;

@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioUnit midiInstrument;

@end

@implementation MIKMIDIEndpointSynthesizer

- (instancetype)init
{
	return [self initWithMIDISource:nil];
}

+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	return [[self alloc] initWithMIDISource:source];
}

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	self = [super init];
	if (self) {
		if (source) {
			NSError *error = nil;
			if (![self connectToMIDISource:source error:&error]) {
				NSLog(@"Unable to connect to MIDI source %@: %@", source, error);
				return nil;
			}
			_endpoint = source;
		}
		_componentDescription = componentDescription;
		if (![self setupAUGraph]) return nil;
	}
	return self;
}

+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;
{
	return [[self alloc] initWithClientDestinationEndpoint:destination];
}

- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination;
{
	if (!destination) {
		[NSException raise:NSInvalidArgumentException format:@"%s requires a non-nil destination endpoint argument.", __PRETTY_FUNCTION__];
		return nil;
	}
	
	self = [super init];
	if (self) {
		
		__weak MIKMIDIEndpointSynthesizer *weakSelf = self;
		destination.receivedMessagesHandler = ^(MIKMIDIClientDestinationEndpoint *destination, NSArray *commands){
			__strong MIKMIDIEndpointSynthesizer *strongSelf = weakSelf;
			[strongSelf handleMIDIMessages:commands];
		};
		_endpoint = destination;
		
		if (![self setupAUGraph]) return nil;
	}
	return self;
}

- (void)dealloc
{
	if (self.endpoint) {
		if ([self.endpoint isKindOfClass:[MIKMIDISourceEndpoint class]]) {
			[[MIKMIDIDeviceManager sharedDeviceManager] disconnectInput:(MIKMIDISourceEndpoint *)self.endpoint forConnectionToken:self.connectionToken];
		} else if ([self.endpoint isKindOfClass:[MIKMIDIClientDestinationEndpoint class]]) {
			[(MIKMIDIClientDestinationEndpoint *)self.endpoint setReceivedMessagesHandler:nil];
		}
	}
	
	self.graph = NULL;
}

#pragma mark - Private

- (BOOL)connectToMIDISource:(MIKMIDISourceEndpoint *)source error:(NSError **)error
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	
	__weak MIKMIDIEndpointSynthesizer *weakSelf = self;
	MIKMIDIDeviceManager *deviceManager = [MIKMIDIDeviceManager sharedDeviceManager];
	id connectionToken = [deviceManager connectInput:source error:error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		__strong MIKMIDIEndpointSynthesizer *strongSelf = weakSelf;
		[strongSelf handleMIDIMessages:commands];
		
	}];
	
	if (!connectionToken) return NO;
	
	self.endpoint = source;
	self.connectionToken = connectionToken;
	return YES;
}

- (void)handleMIDIMessages:(NSArray *)commands
{
	for (MIKMIDICommand *command in commands) {
		OSStatus err = MusicDeviceMIDIEvent(self.midiInstrument, command.commandType, command.dataByte1, command.dataByte2, 0);
		if (err) NSLog(@"Unable to send MIDI command to synthesizer %@: %i", command, err);
	}
}

#pragma mark Audio Graph

- (BOOL)setupAUGraph
{
	AUGraph graph;
	OSStatus err = 0;
	if ((err = NewAUGraph(&graph))) {
		NSLog(@"Unable to create AU graph: %i", err);
		return NO;
	}
	
	AudioComponentDescription outputcd = {0};
	outputcd.componentType = kAudioUnitType_Output;
	outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
	outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	AUNode outputNode;
	if ((err = AUGraphAddNode(graph, &outputcd, &outputNode))) {
		NSLog(@"Unable to add ouptput node to graph: %i", err);
		return NO;
	}
	
	AudioComponentDescription instrumentcd = {0};
	instrumentcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	instrumentcd.componentType = kAudioUnitType_MusicDevice;
#if TARGET_OS_IPHONE
	instrumentcd.componentSubType = kAudioUnitSubType_Sampler;
#else
	instrumentcd.componentSubType = kAudioUnitSubType_DLSSynth;
#endif
	
	AUNode instrumentNode;
	if ((err = AUGraphAddNode(graph, &instrumentcd, &instrumentNode))) {
		NSLog(@"Unable to add instrument node to AU graph: %i", err);
		return NO;
	}
	
	if ((err = AUGraphOpen(graph))) {
		NSLog(@"Unable to open AU graph: %i", err);
		return NO;
	}
	
	AudioUnit instrumentUnit;
	if ((err = AUGraphNodeInfo(graph, instrumentNode, NULL, &instrumentUnit))) {
		NSLog(@"Unable to get instrument AU unit: %i", err);
		return NO;
	}
	
	if ((err = AUGraphConnectNodeInput(graph, instrumentNode, 0, outputNode, 0))) {
		NSLog(@"Unable to connect instrument to output: %i", err);
		return NO;
	}
	
	if ((err = AUGraphInitialize(graph))) {
		NSLog(@"Unable to initialize AU graph: %i", err);
		return NO;
	}
	
	if ((err = AUGraphStart(graph))) {
		NSLog(@"Unable to start AU graph: %i", err);
		return NO;
	}
	
	self.graph = graph;
	self.midiInstrument = instrumentUnit;
	
	return YES;
}


#pragma mark - Properties

- (void)setGraph:(AUGraph)graph
{
	if (graph != _graph) {
		if (_graph) DisposeAUGraph(_graph);
		_graph = graph;
	}
}

@end

#endif // !TARGET_OS_IPHONE