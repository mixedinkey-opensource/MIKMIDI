//
//  MIKMIDISynthesizer.m
//
//
//  Created by Andrew Madsen on 2/19/15.
//
//

#import "MIKMIDISynthesizer.h"
#import "MIKMIDICommand.h"
#import "MIKMIDISynthesizer_SubclassMethods.h"
#import "MIKMIDIErrors.h"
#import "MIKMIDIClock.h"
#import "MIKMIDIPrivate.h"
#import <AVFoundation/AVFoundation.h>

@interface MIKMIDISynthesizer ()
{
	CFMutableDictionaryRef _scheduledCommandsByTimeStamp;
	CFMutableSetRef _scheduledCommandTimeStampsSet;
	CFMutableArrayRef _scheduledCommandTimeStampsArray;

	dispatch_queue_t _scheduledCommandQueue;
}

@property (strong) AVAudioUnitSampler *instrument;
@property (strong) AVAudioEngine *engine;

@end


@implementation MIKMIDISynthesizer

- (instancetype)init
{
	return [self initWithError:NULL];
}

- (instancetype)initWithError:(NSError **)error
{
	return [self initWithAudioUnitDescription:[[self class] appleSynthComponentDescription] error:error];
}

- (instancetype)initWithAudioUnitDescription:(AudioComponentDescription)componentDescription error:(NSError ** _Nullable)error
{
	self = [super init];
	if (self) {
		NSString *queueLabel = [[[NSBundle mainBundle] bundleIdentifier] stringByAppendingFormat:@".%@.%p", [self class], self];
		dispatch_queue_attr_t attr = DISPATCH_QUEUE_SERIAL;

#if defined (__MAC_10_10) || defined (__IPHONE_8_0)
		if (@available(macOS 10.10, iOS 8, *)) {
			if (&dispatch_queue_attr_make_with_qos_class != NULL) {
				attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
			}
		}
#endif
		_scheduledCommandQueue = dispatch_queue_create(queueLabel.UTF8String, attr);

		_componentDescription = componentDescription;
		if (![self setupAUGraphWithError:error]) { return nil; }

		self.sendMIDICommand = ^(MIKMIDISynthesizer *synth, MusicDeviceComponent inUnit, UInt32 inStatus, UInt32 inData1, UInt32 inData2, UInt32 inOffsetSampleFrame) {
			return MusicDeviceMIDIEvent(inUnit, inStatus, inData1, inData2, inOffsetSampleFrame);
		};
	}
	return self;
}

- (void)dealloc
{
	[self.engine stop];
	if (_scheduledCommandsByTimeStamp) {
		CFRelease(_scheduledCommandsByTimeStamp);
		_scheduledCommandsByTimeStamp = NULL;
	}

	if (_scheduledCommandTimeStampsSet) {
		CFRelease(_scheduledCommandTimeStampsSet);
		_scheduledCommandTimeStampsSet = NULL;
	}

	if (_scheduledCommandTimeStampsArray) {
		CFRelease(_scheduledCommandTimeStampsArray);
		_scheduledCommandTimeStampsArray = NULL;
	}
}

#pragma mark - Public

- (NSArray *)availableInstruments
{
	return @[];
}

- (BOOL)selectInstrument:(MIKMIDISynthesizerInstrument *)instrument error:(NSError **)error
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	if (!instrument) {
		*error = [NSError MIKMIDIErrorWithCode:MIKMIDIInvalidArgumentError userInfo:nil];
		return NO;
	}
	return [self sendBankSelectAndProgramChangeForInstrumentID:instrument.instrumentID error:error];
}

- (BOOL)loadSoundfontFromFileAtURL:(NSURL *)fileURL error:(NSError **)error
{
	error = error ? error : &(NSError *__autoreleasing){ nil };

	return [self.instrument loadSoundBankInstrumentAtURL:fileURL program:0 bankMSB:kAUSampler_DefaultMelodicBankMSB bankLSB:kAUSampler_DefaultBankLSB error:error];
}

#pragma mark - Private

- (BOOL)sendBankSelectAndProgramChangeForInstrumentID:(MusicDeviceInstrumentID)instrumentID error:(NSError **)error
{
	error = error ?: &(NSError *__autoreleasing){ nil };

	for (UInt8 channel = 0; channel < 16; channel++) {
		// http://lists.apple.com/archives/coreaudio-api/2002/Sep/msg00015.html


		CFURLRef loadedSoundfontURL = NULL;
		UInt32 size = sizeof(loadedSoundfontURL);
		OSStatus err = AudioUnitGetProperty(self.instrumentUnit,
											kMusicDeviceProperty_SoundBankURL,
											kAudioUnitScope_Global,
											0,
											&loadedSoundfontURL,
											&size);
		if (err && err != kAudioUnitErr_InvalidProperty) {
			NSLog(@"AudioUnitGetProperty() (kMusicDeviceProperty_SoundBankURL) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return NO;
		}

		if (loadedSoundfontURL || [self isUsingAppleDLSSynth]) {

			UInt32 bankSelectStatus = 0xB0 | channel;

			UInt8 bankSelectMSB = (instrumentID >> 16) & 0x7F;
			err = _sendMIDICommand(self, self.instrumentUnit, bankSelectStatus, 0x00, bankSelectMSB, 0);
			if (err) {
				NSLog(@"MusicDeviceMIDIEvent() (MSB Bank Select) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
				*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
				return NO;
			}

			UInt8 bankSelectLSB = (instrumentID >> 8) & 0x7F;
			err = _sendMIDICommand(self, self.instrumentUnit, bankSelectStatus, 0x20, bankSelectLSB, 0);
			if (err) {
				NSLog(@"MusicDeviceMIDIEvent() (LSB Bank Select) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
				*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
				return NO;
			}
		}

		UInt32 programChangeStatus = 0xC0 | channel;
		UInt8 programChange = instrumentID & 0x7F;
		err = _sendMIDICommand(self, self.instrumentUnit, programChangeStatus, programChange, 0, 0);
		if (err) {
			NSLog(@"MusicDeviceMIDIEvent() (Program Change) failed with error %@ in %s.", @(err), __PRETTY_FUNCTION__);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return NO;
		}
	}

	return YES;
}

#pragma mark Audio Graph

- (BOOL)setupAUGraphWithError:(NSError **)error
{
	error = error ?: &(NSError * __autoreleasing){ nil };
	OSStatus err = 0;

	AVAudioEngine *engine = [[AVAudioEngine alloc] init];

	AVAudioUnitSampler *instrument = [[AVAudioUnitSampler alloc] initWithAudioComponentDescription:self.componentDescription];
	[engine attachNode:instrument];
	[engine connect:instrument to:engine.mainMixerNode format:nil];

	[engine prepare];

#if !TARGET_OS_IPHONE
	// Turn down reverb which is way too high by default
	if (self.componentDescription.componentSubType == kAudioUnitSubType_DLSSynth) {
		AudioUnit instrumentUnit = instrument.audioUnit;
		if ((err = AudioUnitSetParameter(instrumentUnit, kMusicDeviceParam_ReverbVolume, kAudioUnitScope_Global, 0, -120, 0))) {
			NSLog(@"Unable to set reverb level to -120: %@", @(err));
		}
	}
#endif

	self.instrument = instrument;
	self.engine = engine;

	[self setupRenderNotify];

	return [engine startAndReturnError:error];
}

- (void)setupRenderNotify
{
	OSStatus err;
	if (self.instrumentUnit) {
		err = AudioUnitRemoveRenderNotify(self.instrumentUnit, MIKMIDISynthesizerInstrumentUnitRenderCallback, (__bridge void *)self);
		if (err) NSLog(@"Unable to remove render notify from instrument unit %p: %@", self.instrumentUnit, @(err));
	}
}

#pragma mark - Instruments

- (BOOL)isUsingAppleSynth
{
	AudioComponentDescription description = self.componentDescription;
	AudioComponentDescription appleSynthDescription = [[self class] appleSynthComponentDescription];
	if (description.componentManufacturer != appleSynthDescription.componentManufacturer) return NO;
	if (description.componentType != appleSynthDescription.componentType) return NO;
	if (description.componentSubType != appleSynthDescription.componentSubType) return NO;
	return YES;
}

- (BOOL)isUsingAppleDLSSynth
{
	return NO;
}

+ (AudioComponentDescription)appleSynthComponentDescription
{
	AudioComponentDescription instrumentcd = (AudioComponentDescription){0};
	instrumentcd.componentManufacturer = kAudioUnitManufacturer_Apple;
	instrumentcd.componentType = kAudioUnitType_MusicDevice;
	instrumentcd.componentSubType = kAudioUnitSubType_Sampler;
	return instrumentcd;
}

#pragma mark - MIKMIDICommandScheduler

- (void)scheduleMIDICommands:(NSArray *)commands
{
	for (MIKMIDICommand *command in commands) {
		[self.instrument sendMIDIEvent:command.commandType data1:command.dataByte1 data2:command.dataByte2];
//
//		dispatch_sync(_scheduledCommandQueue, ^{
//			NSUInteger count = commands.count;
//			if (!self->_scheduledCommandsByTimeStamp) {
//				self->_scheduledCommandsByTimeStamp = CFDictionaryCreateMutable(NULL, count, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
//			}
//			if (!self->_scheduledCommandTimeStampsSet) {
//				self->_scheduledCommandTimeStampsSet = CFSetCreateMutable(NULL, count, &kCFTypeSetCallBacks);
//			}
//			if (!self->_scheduledCommandTimeStampsArray) {
//				self->_scheduledCommandTimeStampsArray = CFArrayCreateMutable(NULL, count, &kCFTypeArrayCallBacks);
//			}
//
//			MIDITimeStamp timeStamp = command.midiTimestamp;
//			void *timeStampNumber = (__bridge void*)@(timeStamp);
//			CFMutableArrayRef commandsAtTimeStamp = (CFMutableArrayRef)CFDictionaryGetValue(self->_scheduledCommandsByTimeStamp, timeStampNumber);
//			if (!commandsAtTimeStamp) {
//				commandsAtTimeStamp = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);
//				CFDictionarySetValue(self->_scheduledCommandsByTimeStamp, timeStampNumber, (void *)commandsAtTimeStamp);
//				CFRelease(commandsAtTimeStamp);
//
//				if (!CFSetContainsValue(self->_scheduledCommandTimeStampsSet, timeStampNumber)) {
//					CFSetAddValue(self->_scheduledCommandTimeStampsSet, timeStampNumber);
//					CFArrayAppendValue(self->_scheduledCommandTimeStampsArray, timeStampNumber);
//				}
//			}
//
//			CFArrayAppendValue(commandsAtTimeStamp, (__bridge void *)command);
//		});
	}
}

#pragma mark - Callbacks

OSStatus MIKMIDISynthesizerScheduleUpcomingMIDICommands(MIKMIDISynthesizer *synth, AudioUnit instrumentUnit, UInt32 inNumberFrames, Float64 sampleRate, const AudioTimeStamp *inTimeStamp)
{
	dispatch_queue_t queue = synth->_scheduledCommandQueue;
	if (!queue) return noErr;	// no commands have been scheduled with this synth

	static NSTimeInterval lastTimeUntilNextCallback = 0;
	static MIDITimeStamp lastMIDITimeStampsUntilNextCallback = 0;
	NSTimeInterval timeUntilNextCallback = inNumberFrames / sampleRate;
	MIDITimeStamp midiTimeStampsUntilNextCallback = lastMIDITimeStampsUntilNextCallback;

	if (lastTimeUntilNextCallback != timeUntilNextCallback) {
		midiTimeStampsUntilNextCallback = MIKMIDIClockMIDITimeStampsPerTimeInterval(timeUntilNextCallback);
		lastTimeUntilNextCallback = timeUntilNextCallback;
		lastMIDITimeStampsUntilNextCallback = midiTimeStampsUntilNextCallback;
	}

	MIDITimeStamp toTimeStamp = inTimeStamp->mHostTime + midiTimeStampsUntilNextCallback;
	CFMutableArrayRef commandsToSend = CFArrayCreateMutable(NULL, 0, &kCFTypeArrayCallBacks);;

	dispatch_sync(queue, ^{
		CFMutableDictionaryRef commandsByTimeStamp = synth->_scheduledCommandsByTimeStamp;
		if (!commandsByTimeStamp || !CFDictionaryGetCount(commandsByTimeStamp)) return;


		CFMutableSetRef commandTimeStampsSet = synth->_scheduledCommandTimeStampsSet;
		CFMutableArrayRef commandTimeStampsArray = synth->_scheduledCommandTimeStampsArray;
		if (!commandTimeStampsSet || !commandTimeStampsArray) return;

		CFArrayRef commandTimeStampsArrayCopy = CFArrayCreateCopy(NULL, commandTimeStampsArray);
		CFIndex count = CFArrayGetCount(commandTimeStampsArrayCopy);
		for (CFIndex i = 0; i < count; i++) {
			NSNumber *timeStampNumber = (__bridge NSNumber *)CFArrayGetValueAtIndex(commandTimeStampsArrayCopy, i);
			MIDITimeStamp timeStamp = timeStampNumber.unsignedLongLongValue;
			if (timeStamp >= toTimeStamp) break;

			CFMutableArrayRef commandsAtTimeStamp = (CFMutableArrayRef)CFDictionaryGetValue(commandsByTimeStamp, (__bridge void*)timeStampNumber);
			CFArrayAppendArray(commandsToSend, commandsAtTimeStamp, CFRangeMake(0, CFArrayGetCount(commandsAtTimeStamp)));

			CFDictionaryRemoveValue(commandsByTimeStamp, (__bridge void *)timeStampNumber);
			CFSetRemoveValue(commandTimeStampsSet, (__bridge void*)timeStampNumber);
			CFArrayRemoveValueAtIndex(commandTimeStampsArray, 0);
		}
		CFRelease(commandTimeStampsArrayCopy);
	});

	NSTimeInterval secondsPerMIDITimeStamp = MIKMIDIClockSecondsPerMIDITimeStamp();

	CFIndex commandCount = CFArrayGetCount(commandsToSend);
	for (CFIndex i = 0; i < commandCount; i++) {
		MIKMIDICommand *command = (__bridge MIKMIDICommand *)CFArrayGetValueAtIndex(commandsToSend, i);

		MIDITimeStamp sendTimeStamp = command.midiTimestamp;
		if (sendTimeStamp < inTimeStamp->mHostTime) sendTimeStamp = inTimeStamp->mHostTime;
		MIDITimeStamp timeStampOffset = sendTimeStamp - inTimeStamp->mHostTime;
		Float64 sampleOffset = secondsPerMIDITimeStamp * timeStampOffset * sampleRate;

		OSStatus err = synth->_sendMIDICommand(synth, instrumentUnit, command.statusByte, command.dataByte1, command.dataByte2, sampleOffset);
		if (err) {
			NSLog(@"Unable to schedule MIDI command %@ for instrument unit %p: %@", command, instrumentUnit, @(err));
			return err;
		}
	}

	CFRelease(commandsToSend);
	return noErr;
}

static OSStatus MIKMIDISynthesizerInstrumentUnitRenderCallback(void *						inRefCon,
															   AudioUnitRenderActionFlags *	ioActionFlags,
															   const AudioTimeStamp *		inTimeStamp,
															   UInt32						inBusNumber,
															   UInt32						inNumberFrames,
															   AudioBufferList *			ioData)
{
	if (*ioActionFlags & kAudioUnitRenderAction_PreRender) {
		if (!(inTimeStamp->mFlags & kAudioTimeStampHostTimeValid)) return noErr;
		if (!(inTimeStamp->mFlags & kAudioTimeStampSampleTimeValid)) return noErr;

		MIKMIDISynthesizer *synth = (__bridge MIKMIDISynthesizer *)inRefCon;
		AudioUnit instrumentUnit = synth.instrumentUnit;
		AudioStreamBasicDescription LPCMASBD;
		UInt32 sizeOfLPCMASBD = sizeof(LPCMASBD);
		OSStatus err = AudioUnitGetProperty(instrumentUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &LPCMASBD, &sizeOfLPCMASBD);
		if (err) {
			NSLog(@"Unable to get stream description for instrument unit %p: %@", instrumentUnit, @(err));
			return err;
		}

		return MIKMIDISynthesizerScheduleUpcomingMIDICommands(synth, instrumentUnit, inNumberFrames, LPCMASBD.mSampleRate, inTimeStamp);
	}
	return noErr;
}

#pragma mark - Properties

- (void)handleMIDIMessages:(NSArray *)commands
{
	for (MIKMIDICommand *command in commands) {
		OSStatus err = _sendMIDICommand(self, self.instrumentUnit, command.statusByte, command.dataByte1, command.dataByte2, 0);
		if (err) NSLog(@"Unable to send MIDI command to synthesizer %@: %@", command, @(err));
	}
}

- (AudioUnit)instrumentUnit { return self.instrument.audioUnit; }

@end
