//
//  MIKMIDIMappingGenerator.m
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMappingGenerator.h"

#import "MIKMIDI.h"
#import "MIKMIDIMapping.h"

#define kMIKMIDILearningTimeoutInterval 0.6

@interface MIKMIDIMappingGenerator ()

@property (nonatomic, strong, readwrite) MIKMIDIMapping *mapping;

@property (nonatomic, strong) id<MIKMIDIResponder> controlBeingLearned;
@property (nonatomic, strong) MIKMIDIMappingGeneratorMappingCompletionBlock currentMappingCompletionBlock;

@property (nonatomic, strong) NSTimer *messagesTimeoutTimer;
@property (nonatomic, strong) NSMutableArray *receivedMessages;

@end

@implementation MIKMIDIMappingGenerator

+ (instancetype)mappingGeneratorWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;
{
	return [[self alloc] initWithDevice:device error:error];
}

- (instancetype)initWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	self = [super init];
	if (self) {
		self.mapping = [[MIKMIDIMapping alloc] init];
		self.device = device;
		if (![self connectToDevice:error]) {
			NSLog(@"MIDI Mapping Generator could not connect to device: %@", device);
			self = nil;
			return nil;
		}
		self.mapping.controllerName = device.name;
		
		self.receivedMessages = [NSMutableArray array];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		__weak MIKMIDIMappingGenerator *weakSelf = self;
		[nc addObserverForName:MIKMIDIDeviceWasRemovedNotification
						object:nil
						 queue:[NSOperationQueue mainQueue]
					usingBlock:^(NSNotification *note) {
						MIKMIDIDevice *device = [[note userInfo] objectForKey:MIKMIDIDeviceKey];
						if (![device isEqual:self.device]) return;
						[self disconnectFromDevice];
						weakSelf.device = nil;
						NSError *error = [NSError MIKMIDIErrorWithCode:MIKMIDIDeviceConnectionLostErrorCode userInfo:nil];
						[weakSelf finishMappingItem:nil error:error];
					}];
	}
	return self;
}

- (id)init
{
	[NSException raise:NSInternalInconsistencyException format:@"-initWithDevice: is the designated initializer for %@", NSStringFromClass([self class])];
	self = nil;
	return nil;
}

- (void)dealloc
{
	self.messagesTimeoutTimer = nil;
    [self disconnectFromDevice];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (void)learnMappingForControl:(id<MIKMIDIResponder>)control completionBlock:(MIKMIDIMappingGeneratorMappingCompletionBlock)completionBlock;
{
	self.currentMappingCompletionBlock = completionBlock;
	self.controlBeingLearned = control;
}

#pragma mark - Private

- (void)handleMIDICommand:(MIKMIDIChannelVoiceCommand *)command
{
	NSUInteger controllerNumber = MIKMIDIMappingControlNumberFromCommand(command);
	MIKMIDIMappingItem *existingMappingItem = [self.mapping mappingItemForControlNumber:controllerNumber];
	if (existingMappingItem) return; // This commmand is already mapped so ignore it
	
	if ([self.receivedMessages count]) {
		MIKMIDIChannelVoiceCommand *firstMessage = [self.receivedMessages objectAtIndex:0];
		// If we get a message from a different controller number, restart the mapping
		if (MIKMIDIMappingControlNumberFromCommand(firstMessage) != MIKMIDIMappingControlNumberFromCommand(command) ||
			firstMessage.channel != command.channel) {
			[self.receivedMessages removeAllObjects];
		}
	}
	
	if (![self.controlBeingLearned respondsToMIDICommand:command]) return;
	
	[self.receivedMessages addObject:command];
	self.messagesTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:kMIKMIDILearningTimeoutInterval
																 target:self
															   selector:@selector(timeoutTimerFired:)
															   userInfo:nil
																repeats:NO];
	
	if ([self.receivedMessages count] > 3) { // Don't try to finish unless we've received several messages (eg. from a knob) already
		MIKMIDIMappingItem *mappingItem = [self mappingItemForControl:self.controlBeingLearned fromReceivedMessages:self.receivedMessages];
		if (mappingItem) [self finishMappingItem:mappingItem error:nil];
	}
}

#pragma mark Messages to Mapping Item

- (MIKMIDIMappingItem *)buttonMappingItemFromMessages:(NSArray *)messages
{
	if (![messages count]) return nil;
	if ([messages count] > 2) return nil;
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	
	MIKMIDIMappingItem *result = [[MIKMIDIMappingItem alloc] init];
	result.commandIdentifier = [self.controlBeingLearned MIDIIdentifier];
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIMappingControlNumberFromCommand(firstMessage);

	// Tap type button
	if ([messages count] == 1) {
		if ([[NSDate date] timeIntervalSinceDate:firstMessage.timestamp] < kMIKMIDILearningTimeoutInterval) return nil; // Need to keep waiting for another message
		
		result.interactionType = MIKMIDIMappingInteractionTypeTap;
	}
	
	// Key type button
	if ([messages count] == 2) {		
		MIKMIDIChannelVoiceCommand *secondMessage = [messages objectAtIndex:1];
		BOOL firstIsZero = firstMessage.value == 0 || firstMessage.commandType == MIKMIDICommandTypeNoteOff;
		BOOL secondIsZero = secondMessage.value == 0 || secondMessage.commandType == MIKMIDICommandTypeNoteOff;
		
		result.interactionType = (!firstIsZero && secondIsZero) ? MIKMIDIMappingInteractionTypeKey : MIKMIDIMappingInteractionTypeTap;
	}
	
	return result;
}

- (MIKMIDIMappingItem *)relativeKnobMappingItemFromMessages:(NSArray *)messages
{
	if ([messages count] < 3) return nil;
	
	// Disallow non-control change messages
	for (MIKMIDIChannelVoiceCommand *message in messages) { if (message.commandType != MIKMIDICommandTypeControlChange) return nil; }
	
	NSSet *messageValues = [NSSet setWithArray:[messages valueForKey:@"value"]];
	// If there are more than 2 message values, it's more likely an absolute knob.
	if ([messages count] == [messageValues count] || [messageValues count] > 2) return nil;
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	
	MIKMIDIMappingItem *result = [[MIKMIDIMappingItem alloc] init];
	result.interactionType = MIKMIDIMappingInteractionTypeJogWheel;
	result.commandIdentifier = [self.controlBeingLearned MIDIIdentifier];
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIMappingControlNumberFromCommand(firstMessage);
	result.flipped = ([(MIKMIDIChannelVoiceCommand *)[messages lastObject] value] < 64);
	return result;
}

- (MIKMIDIMappingItem *)absoluteKnobSliderMappingItemFromMessages:(NSArray *)messages
{
	if ([messages count] < 3) return nil;
	
	// Disallow non-control change messages
	for (MIKMIDIChannelVoiceCommand *message in messages) { if (message.commandType != MIKMIDICommandTypeControlChange) return nil; }
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	MIKMIDIMappingItem *result = [[MIKMIDIMappingItem alloc] init];
	result.interactionType = MIKMIDIMappingInteractionTypeAbsoluteKnobSlider;
	result.commandIdentifier = [self.controlBeingLearned MIDIIdentifier];
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIMappingControlNumberFromCommand(firstMessage);
	
	// Figure out which direction it goes
	NSInteger directionCounter = 0;
	MIKMIDIChannelVoiceCommand *previousMessage = (MIKMIDIChannelVoiceCommand *)firstMessage;
	for (MIKMIDIChannelVoiceCommand *message in messages) {
		if (message.value > previousMessage.value) directionCounter++;
		if (message.value < previousMessage.value) directionCounter--;
		previousMessage = message;
	}
	result.flipped = (directionCounter < 0);
	
	return result;
}

- (MIKMIDIMappingItem *)mappingItemForControl:(id<MIKMIDIResponder>)responder fromReceivedMessages:(NSArray *)messages
{
	if (![messages count]) return nil;
	/* The logic here is as follows:
	 
	 For knobs and sliders:
	 We assume knobs/sliders have been moved from right-to-left or top-to-bottom, meaning increasing.
	 If the message values *decrease*, it's an indication that the control is flipped from what we expect,
	 and we need to handle that.
	 
	 If the value of each message is the same, or flips between two binary values (e.g. user twisted back and forth),
	 it's a jog wheel rather than an absolute pot.
	 
	 For buttons:
	 If we've only got one message, and it has been more than the timeout interval since then, the button is a tap type button.
	 If we've gotten two messages, with the second having value 0, the button is a key type button.
	 */
	
	MIKMIDIResponderType responderType = MIKMIDIResponderTypeAll;
	if ([responder respondsToSelector:@selector(MIDIResponderType)]) {
		responderType = [responder MIDIResponderType];
	}
	
	// Button
	if (responderType & MIKMIDIResponderTypeButton) {
		MIKMIDIMappingItem *buttonMappingItem = [self buttonMappingItemFromMessages:messages];
		if (buttonMappingItem) return buttonMappingItem;
	}
	
	// Relative knob/jog wheel
	if (responderType & MIKMIDIResponderTypeRelativeKnob) {
		MIKMIDIMappingItem *relativeKnobMappingItem = [self relativeKnobMappingItemFromMessages:messages];
		if (relativeKnobMappingItem) return relativeKnobMappingItem;
	}
	
	// Absolute knob/slider
	if (responderType & MIKMIDIResponderTypeAbsoluteSliderOrKnob) {
		MIKMIDIMappingItem *absoluteKnobSliderMappingItem = [self absoluteKnobSliderMappingItemFromMessages:messages];
		if (absoluteKnobSliderMappingItem) return absoluteKnobSliderMappingItem;
	}
	
	return nil;
}

- (void)timeoutTimerFired:(NSTimer *)timer
{
	MIKMIDIMappingItem *mappingItem = [self mappingItemForControl:self.controlBeingLearned fromReceivedMessages:self.receivedMessages];
	if (mappingItem) {
		[self finishMappingItem:mappingItem error:nil];
	} else {
		// Start over listening
		[self.receivedMessages removeAllObjects];
	}
}

- (void)finishMappingItem:(MIKMIDIMappingItem *)mappingItem error:(NSError *)errorOrNil
{
	MIKMIDIMappingGeneratorMappingCompletionBlock completionBlock = self.currentMappingCompletionBlock;
	self.currentMappingCompletionBlock = nil;
	[self.receivedMessages removeAllObjects];
	self.messagesTimeoutTimer = nil;
	if (mappingItem) [self.mapping addMappingItemsObject:mappingItem];
	if (completionBlock) completionBlock(mappingItem, errorOrNil);
}

#pragma mark Device Connection/Disconnection

- (BOOL)connectToDevice:(NSError **)error
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	if (!self.device) {
		*error = [NSError MIKMIDIErrorWithCode:MIKMIDIUnknownErrorCode userInfo:nil];
		return NO;
	}
	
	NSArray *sources = [self.device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	if (![sources count]) return NO;
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	
	MIKMIDIDeviceManager *manager = [MIKMIDIDeviceManager sharedDeviceManager];
	__weak MIKMIDIMappingGenerator *weakSelf = self;
	BOOL success = [manager connectInput:source error:error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		for (MIKMIDICommand *command in commands) {
			if (![command isKindOfClass:[MIKMIDIChannelVoiceCommand class]]) continue;
			[weakSelf handleMIDICommand:(MIKMIDIChannelVoiceCommand *)command];
		}
	}];
	return success;
}

- (void)disconnectFromDevice
{
	NSArray *sources = [self.device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	if (![sources count]) return;
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	[[MIKMIDIDeviceManager sharedDeviceManager] disconnectInput:source];
}

#pragma mark - Properties

- (void)setMessagesTimeoutTimer:(NSTimer *)messagesTimeoutTimer
{
	if (messagesTimeoutTimer != _messagesTimeoutTimer) {
		[_messagesTimeoutTimer invalidate];
		_messagesTimeoutTimer = messagesTimeoutTimer;
	}
}

@end
