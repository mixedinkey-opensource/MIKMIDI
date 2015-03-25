//
//  MIKMIDISynthesizerInstrument.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/19/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDISynthesizerInstrument.h"

@implementation MIKMIDISynthesizerInstrument

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
			NSLog(@"Unable to create the default synthesizer instrument audio unit.");
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
			
			MIKMIDISynthesizerInstrument *instrument = [MIKMIDISynthesizerInstrument instrumentWithID:instrumentID];
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
