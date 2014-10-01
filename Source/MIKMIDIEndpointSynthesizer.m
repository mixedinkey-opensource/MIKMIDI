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
#import "MIKMIDI.h"
#import "MIKMIDIClientDestinationEndpoint.h"

@interface MIKMIDIEndpointSynthesizer ()

@property (nonatomic, strong, readwrite) MIKMIDIEndpoint *endpoint;
@property (nonatomic, strong) id connectionToken;

@property (nonatomic) AUGraph graph;
@property (nonatomic) AudioUnit midiInstrument;

@end

@implementation MIKMIDIEndpointSynthesizer

+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	return [[self alloc] initWithMIDISource:source];
}

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	if (!source) {
		[NSException raise:NSInvalidArgumentException format:@"%s requires a non-nil device argument.", __PRETTY_FUNCTION__];
		return nil;
	}
	
	self = [super init];
	if (self) {
		NSError *error = nil;
		if (![self connectToMIDISource:source error:&error]) {
			NSLog(@"Unable to connect to MIDI source %@: %@", source, error);
			return nil;
		}
		_endpoint = source;
		
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
		[NSException raise:NSInvalidArgumentException format:@"%s requires a non-nil device argument.", __PRETTY_FUNCTION__];
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

- (void)noteOn:(UInt8)note velocity:(UInt8)velocity channel:(UInt8)channel
{
	MIKMutableMIDINoteOnCommand *noteOn = [MIKMutableMIDINoteOnCommand commandForCommandType:MIKMIDICommandTypeNoteOn];
	noteOn.note = note;
	noteOn.channel = channel;
	noteOn.velocity = velocity;
	[self handleMIDIMessages:@[noteOn]];
}

- (void)noteOff:(UInt8)note velocity:(UInt8)velocity channel:(UInt8)channel
{
	MIKMutableMIDINoteOffCommand *noteOff = [MIKMutableMIDINoteOffCommand commandForCommandType:MIKMIDICommandTypeNoteOff];
	noteOff.note = note;
	noteOff.channel = channel;
	noteOff.velocity = velocity;
	[self handleMIDIMessages:@[noteOff]];
}

- (void)noteOff:(UInt8)note channel:(UInt8)channel
{
	[self noteOff:note velocity:0 channel:channel];
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


#pragma mark - Instruments

- (BOOL)selectInstrument:(MIKMIDIEndpointSynthesizerInstrument *)instrument;
{
	if (!instrument) return NO;
	
	MusicDeviceInstrumentID instrumentID = instrument.instrumentID;
	for (UInt8 channel = 0; channel < 16; channel++) {
		// http://lists.apple.com/archives/coreaudio-api/2002/Sep/msg00015.html
		UInt8 bankSelectMSB = (instrumentID >> 16) & 0x7F;
		UInt8 bankSelectLSB = (instrumentID >> 8) & 0x7F;
		UInt8 programChange = instrumentID & 0x7F;
		
		UInt32 bankSelectStatus = 0xB0 | channel;
		UInt32 programChangeStatus = 0xC0 | channel;
		
		AudioUnit instrumentUnit = self.midiInstrument;
		OSStatus err = MusicDeviceMIDIEvent(instrumentUnit, bankSelectStatus, 0x00, bankSelectMSB, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (MSB Bank Select) failed with error %d in %s.", err, __PRETTY_FUNCTION__);
			return NO;
		}
		
		err = MusicDeviceMIDIEvent(instrumentUnit, bankSelectStatus, 0x20, bankSelectLSB, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (LSB Bank Select) failed with error %d in %s.", err, __PRETTY_FUNCTION__);
			return NO;
		}
		
		err = MusicDeviceMIDIEvent(instrumentUnit, programChangeStatus, programChange, 0, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (Program Change) failed with error %d in %s.", err, __PRETTY_FUNCTION__);
			return NO;
		}
	}
	
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

#pragma mark -

@implementation MIKMIDIEndpointSynthesizerInstrument

+ (AudioUnit)instrumentUnit
{
	static AudioUnit instrumentUnit = NULL;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		AudioComponentDescription componentDesc = {
			.componentManufacturer = kAudioUnitManufacturer_Apple,
			.componentType = kAudioUnitType_MusicDevice,
			.componentSubType = kAudioUnitSubType_DLSSynth,
		};
		AudioComponent instrumentComponent = AudioComponentFindNext(NULL, &componentDesc);
		if (!instrumentComponent) {
			NSLog(@"Unable to create the DLSSynth audio unit.");
			return;
		}
		AudioComponentInstanceNew(instrumentComponent, &instrumentUnit);
		AudioUnitInitialize(instrumentUnit);
	});
	
	return instrumentUnit;
}

+ (NSArray *)availableInstruments
{
	static NSArray *availableInstruments = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		AudioUnit audioUnit = [self instrumentUnit];
		NSMutableArray *result = [NSMutableArray array];
		
		UInt32 instrumentCount;
		UInt32 instrumentCountSize = sizeof(instrumentCount);
		
		OSStatus err = AudioUnitGetProperty(audioUnit, kMusicDeviceProperty_InstrumentCount, kAudioUnitScope_Global, 0, &instrumentCount, &instrumentCountSize);
		if (err) {
			NSLog(@"AudioUnitGetProperty() (Instrument Count) failed with error %d in %s.", err, __PRETTY_FUNCTION__);
			return;
		}
		
		for (UInt32 i = 0; i < instrumentCount; i++) {
			MusicDeviceInstrumentID instrumentID;
			UInt32 idSize = sizeof(instrumentID);
			err = AudioUnitGetProperty(audioUnit, kMusicDeviceProperty_InstrumentNumber, kAudioUnitScope_Global, i, &instrumentID, &idSize);
			if (err) {
				NSLog(@"AudioUnitGetProperty() (Instrument Number) failed with error %d in %s.", err, __PRETTY_FUNCTION__);
				continue;
			}
			
			MIKMIDIEndpointSynthesizerInstrument *instrument = [MIKMIDIEndpointSynthesizerInstrument instrumentWithID:instrumentID];
			if (instrument) [result addObject:instrument];
		}
		
		availableInstruments = [result copy];
	});
	
	return availableInstruments;
}

+ (instancetype)instrumentWithID:(MusicDeviceInstrumentID)instrumentID;
{
	char cName[256];
	UInt32 cNameSize = sizeof(cName);
	OSStatus err = AudioUnitGetProperty([self instrumentUnit], kMusicDeviceProperty_InstrumentName, kAudioUnitScope_Global, instrumentID, &cName, &cNameSize);
	if (err) {
		NSLog(@"AudioUnitGetProperty() failed with error %d in %s.", err, __PRETTY_FUNCTION__);
		return nil;
	}
	
	NSString *name = [NSString stringWithCString:cName encoding:NSASCIIStringEncoding];
	return [[self alloc] initWithName:name instrumentID:instrumentID];
}

- (instancetype)initWithName:(NSString *)name instrumentID:(MusicDeviceInstrumentID)instrumentID
{
	self = [super init];
	if (self) {
		_name = name;
		_instrumentID = instrumentID;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@", self.name];
}

- (BOOL)isEqual:(id)object
{
	if (![object isMemberOfClass:[self class]]) return NO;
	if (!self.instrumentID == [object instrumentID]) return NO;
	return [self.name isEqualToString:[object name]];
}

- (NSUInteger)hash
{
	return [[NSString stringWithFormat:@"%d-%@", self.instrumentID, self.name] hash];
}

@end

#endif // !TARGET_OS_IPHONE