//
//  MIKMIDIEndpointSynthesizer.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 5/27/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEndpointSynthesizer.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MIKMIDI.h"
#import "MIKMIDIClientDestinationEndpoint.h"

#if !__has_feature(objc_arc)
#error MIKMIDIEndpointSynthesizer.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@interface MIKMIDIEndpointSynthesizer ()

@property (nonatomic, strong, readwrite) MIKMIDIEndpoint *endpoint;

@property (nonatomic, strong) id connectionToken;
@property (readonly, nonatomic) BOOL isUsingAppleSynth;

@end

@implementation MIKMIDIEndpointSynthesizer

- (instancetype)init
{
	return [self initWithMIDISource:nil];
}

+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	return [self playerWithMIDISource:source componentDescription:[self appleSynthComponentDescription]];
}

+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source componentDescription:(AudioComponentDescription)componentDescription
{
	return [[self alloc] initWithMIDISource:source];
}

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source
{
	return [self initWithMIDISource:source componentDescription:[[self class] appleSynthComponentDescription]];
}

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source componentDescription:(AudioComponentDescription)componentDescription;
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
			_componentDescription = componentDescription;
		}
		_componentDescription = componentDescription;
		if (![self setupAUGraph]) return nil;
	}
	return self;
}

+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination
{
	return [self synthesizerWithClientDestinationEndpoint:destination componentDescription:[self appleSynthComponentDescription]];
}

+ (instancetype)synthesizerWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination componentDescription:(AudioComponentDescription)componentDescription
{
	return [[self alloc] initWithClientDestinationEndpoint:destination componentDescription:componentDescription];
}

- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination
{
	return [self initWithClientDestinationEndpoint:destination componentDescription:[[self class] appleSynthComponentDescription]];
}

- (instancetype)initWithClientDestinationEndpoint:(MIKMIDIClientDestinationEndpoint *)destination componentDescription:(AudioComponentDescription)componentDescription
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
		_componentDescription = componentDescription;
		
		if (![self setupAUGraph]) return nil;
	}
	return self;
}

- (void)dealloc
{
	if (self.endpoint) {
		if ([self.endpoint isKindOfClass:[MIKMIDISourceEndpoint class]]) {
			[[MIKMIDIDeviceManager sharedDeviceManager] disconnectInput:(MIKMIDISourceEndpoint *)self.endpoint forConnectionToken:self.connectionToken];
		}
		// Don't need to do anything for a destination endpoint. __weak reference in the messages handler will automatically nil out.
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
		OSStatus err = MusicDeviceMIDIEvent(self.instrument, command.commandType, command.dataByte1, command.dataByte2, 0);
		if (err) NSLog(@"Unable to send MIDI command to synthesizer %@: %@", command, @(err));
	}
}

- (BOOL)sendBankSelectAndProgramChangeForInstrumentID:(MusicDeviceInstrumentID)instrumentID error:(NSError **)error
{
	error = error ?: &(NSError *__autoreleasing){ nil };
	
	for (UInt8 channel = 0; channel < 16; channel++) {
		// http://lists.apple.com/archives/coreaudio-api/2002/Sep/msg00015.html
		UInt8 bankSelectMSB = (instrumentID >> 16) & 0x7F;
		UInt8 bankSelectLSB = (instrumentID >> 8) & 0x7F;
		UInt8 programChange = instrumentID & 0x7F;
		
		UInt32 bankSelectStatus = 0xB0 | channel;
		UInt32 programChangeStatus = 0xC0 | channel;
		
		AudioUnit instrumentUnit = self.instrument;
		OSStatus err = MusicDeviceMIDIEvent(instrumentUnit, bankSelectStatus, 0x00, bankSelectMSB, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (MSB Bank Select) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return NO;
		}
		
		err = MusicDeviceMIDIEvent(instrumentUnit, bankSelectStatus, 0x20, bankSelectLSB, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (LSB Bank Select) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return NO;
		}
		
		err = MusicDeviceMIDIEvent(instrumentUnit, programChangeStatus, programChange, 0, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (Program Change) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return NO;
		}
	}
	
	return YES;
}

#pragma mark Audio Graph

- (BOOL)setupAUGraph
{
	AUGraph graph;
	OSStatus err = 0;
	if ((err = NewAUGraph(&graph))) {
		NSLog(@"Unable to create AU graph: %@", @(err));
		return NO;
	}
	
	AudioComponentDescription outputcd = {0};
	outputcd.componentType = kAudioUnitType_Output;
#if TARGET_OS_IPHONE
	outputcd.componentSubType = kAudioUnitSubType_RemoteIO;
#else
	outputcd.componentSubType = kAudioUnitSubType_DefaultOutput;
#endif
	
	outputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	
	AUNode outputNode;
	if ((err = AUGraphAddNode(graph, &outputcd, &outputNode))) {
		NSLog(@"Unable to add ouptput node to graph: %@", @(err));
		return NO;
	}
	
	AudioComponentDescription instrumentcd = self.componentDescription;
	
	AUNode instrumentNode;
	if ((err = AUGraphAddNode(graph, &instrumentcd, &instrumentNode))) {
		NSLog(@"Unable to add instrument node to AU graph: %@", @(err));
		return NO;
	}
	
	if ((err = AUGraphOpen(graph))) {
		NSLog(@"Unable to open AU graph: %@", @(err));
		return NO;
	}
	
	AudioUnit instrumentUnit;
	if ((err = AUGraphNodeInfo(graph, instrumentNode, NULL, &instrumentUnit))) {
		NSLog(@"Unable to get instrument AU unit: %@", @(err));
		return NO;
	}
	
	if ((err = AUGraphConnectNodeInput(graph, instrumentNode, 0, outputNode, 0))) {
		NSLog(@"Unable to connect instrument to output: %@", @(err));
		return NO;
	}
	
	if ((err = AUGraphInitialize(graph))) {
		NSLog(@"Unable to initialize AU graph: %@", @(err));
		return NO;
	}
	
#if !TARGET_OS_IPHONE
	// Turn down reverb which is way too high by default
	if (instrumentcd.componentSubType == kAudioUnitSubType_DLSSynth) {
		if ((err = AudioUnitSetParameter(instrumentUnit, kMusicDeviceParam_ReverbVolume, kAudioUnitScope_Global, 0, -120, 0))) {
			NSLog(@"Unable to set reverb level to -120: %@", @(err));
		}
	}
#endif
	
	if ((err = AUGraphStart(graph))) {
		NSLog(@"Unable to start AU graph: %@", @(err));
		return NO;
	}
	
	self.graph = graph;
	self.instrument = instrumentUnit;
	
	return YES;
}

+ (AudioComponentDescription)appleSynthComponentDescription
{
	AudioComponentDescription instrumentcd = (AudioComponentDescription){0};
	instrumentcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	instrumentcd.componentType = kAudioUnitType_MusicDevice;
#if TARGET_OS_IPHONE
	instrumentcd.componentSubType = kAudioUnitSubType_Sampler;
#else
	instrumentcd.componentSubType = kAudioUnitSubType_DLSSynth;
#endif
	return instrumentcd;
}


#pragma mark - Instruments

- (BOOL)selectInstrument:(MIKMIDIEndpointSynthesizerInstrument *)instrument;
{
	if (!instrument) return NO;
	if (!self.isUsingAppleSynth) return NO;
	
	MusicDeviceInstrumentID instrumentID = instrument.instrumentID;
	return [self sendBankSelectAndProgramChangeForInstrumentID:instrumentID error:NULL];
}

#pragma mark - Properties

- (void)setGraph:(AUGraph)graph
{
	if (graph != _graph) {
		if (_graph) DisposeAUGraph(_graph);
		_graph = graph;
	}
}

- (BOOL)isUsingAppleSynth
{
	AudioComponentDescription description = self.componentDescription;
	AudioComponentDescription appleSynthDescription = [[self class] appleSynthComponentDescription];
	if (description.componentManufacturer != appleSynthDescription.componentManufacturer) return NO;
	if (description.componentType != appleSynthDescription.componentType) return NO;
	if (description.componentSubType != appleSynthDescription.componentSubType) return NO;
	if (description.componentFlags != appleSynthDescription.componentFlags) return NO;
	if (description.componentFlagsMask != appleSynthDescription.componentFlagsMask) return NO;
	return YES;
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
#if TARGET_OS_IPHONE
			.componentSubType = kAudioUnitSubType_MIDISynth,
#else
			.componentSubType = kAudioUnitSubType_DLSSynth,
#endif
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
			NSLog(@"AudioUnitGetProperty() (Instrument Count) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			return;
		}
		
		for (UInt32 i = 0; i < instrumentCount; i++) {
			MusicDeviceInstrumentID instrumentID;
			UInt32 idSize = sizeof(instrumentID);
			err = AudioUnitGetProperty(audioUnit, kMusicDeviceProperty_InstrumentNumber, kAudioUnitScope_Global, i, &instrumentID, &idSize);
			if (err) {
				NSLog(@"AudioUnitGetProperty() (Instrument Number) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
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
		NSLog(@"AudioUnitGetProperty() failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
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
	if (object == self) return YES;
	if (![object isMemberOfClass:[self class]]) return NO;
	if (!self.instrumentID == [object instrumentID]) return NO;
	return [self.name isEqualToString:[object name]];
}

- (NSUInteger)hash
{
	return (NSUInteger)self.instrumentID;
}

@end
