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
#import "MIKMIDIPrivateUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMappingGenerator.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingGenerator.m in the Build Phases for this target
#endif

@interface MIKMIDIMappingGenerator ()

@property (nonatomic, strong) id<MIKMIDIMappableResponder> controlBeingLearned;
@property (nonatomic, copy) NSString *commandIdentifierBeingLearned;
@property (nonatomic) MIKMIDIResponderType responderTypeOfControlBeingLearned;
@property (nonatomic, strong) MIKMIDIMappingGeneratorMappingCompletionBlock currentMappingCompletionBlock;

@property (nonatomic, strong) NSSet *existingMappingItems;

@property (nonatomic) NSTimeInterval timeoutInteveral;
@property (nonatomic, strong) NSTimer *messagesTimeoutTimer;
@property (nonatomic) NSUInteger numMessagesRequired;
@property (nonatomic, strong) NSMutableArray *receivedMessages;

@property (nonatomic, strong) id connectionToken;
@property (nonatomic, strong) NSMutableArray *blockBasedObservers;

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
		
		self.blockBasedObservers = [NSMutableArray array];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		__weak MIKMIDIMappingGenerator *weakSelf = self;
		id observer = [nc addObserverForName:MIKMIDIDeviceWasRemovedNotification
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
		[self.blockBasedObservers addObject:observer];
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
	
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	for (id observer in self.blockBasedObservers) { [nc removeObserver:observer]; }
	self.blockBasedObservers = nil;
}

#pragma mark - Public

- (void)learnMappingForControl:(id<MIKMIDIMappableResponder>)control
		 withCommandIdentifier:(NSString *)commandID
	 requiringNumberOfMessages:(NSUInteger)numMessages
			 orTimeoutInterval:(NSTimeInterval)timeout
			   completionBlock:(MIKMIDIMappingGeneratorMappingCompletionBlock)completionBlock;
{
	self.existingMappingItems = [self.mapping mappingItemsForCommandIdentifier:commandID responder:control];
	// Determine if existing mapping items for this control should be removed.
	BOOL shouldRemoveExisting = YES;
	if ([self.existingMappingItems count] &&
		[self.delegate respondsToSelector:@selector(mappingGenerator:shouldRemoveExistingMappingItems:forResponderBeingMapped:)]) {
		shouldRemoveExisting = [self.delegate mappingGenerator:self
							  shouldRemoveExistingMappingItems:self.existingMappingItems
									   forResponderBeingMapped:self.controlBeingLearned];
	}
	if (shouldRemoveExisting && [self.existingMappingItems count]) [self.mapping removeMappingItems:self.existingMappingItems];
	
	MIKMIDIResponderType controlResponderType = MIKMIDIResponderTypeAll;
	if ([control respondsToSelector:@selector(MIDIResponderTypeForCommandIdentifier:)]) {
		controlResponderType = [control MIDIResponderTypeForCommandIdentifier:commandID];
		if (controlResponderType == MIKMIDIResponderTypeNone) {
			NSDictionary *userInfo = @{NSLocalizedDescriptionKey : NSLocalizedString(@"MIDI Mapping Failed", @"MIDI Mapping Failed")};
			NSError *error = [NSError MIKMIDIErrorWithCode:MIKMIDIMappingFailedErrorCode userInfo:userInfo];
			[self finishMappingItem:nil error:error];
			return;
		}
	}
	
	self.currentMappingCompletionBlock = completionBlock;
	self.controlBeingLearned = control;
	self.commandIdentifierBeingLearned = commandID;
	self.responderTypeOfControlBeingLearned = controlResponderType;
	self.numMessagesRequired = numMessages ? numMessages : [self defaultMinimumNumberOfMessagesRequiredForResponderType:controlResponderType];
	self.timeoutInteveral = timeout ? timeout : 0.6;
	self.messagesTimeoutTimer = nil;
}

- (void)cancelCurrentCommandLearning;
{
	if (!self.commandIdentifierBeingLearned) return;
	
	if ([self.existingMappingItems count]) [self.mapping addMappingItems:self.existingMappingItems];
	
	NSDictionary *userInfo = [self.existingMappingItems count] ? @{@"PreviouslyExistingMappings" : self.existingMappingItems} : nil;
	NSError *error = [NSError MIKMIDIErrorWithCode:NSUserCancelledError userInfo:userInfo];
	[self finishMappingItem:nil error:error];
}

#pragma mark - Private

- (void)handleMIDICommand:(MIKMIDIChannelVoiceCommand *)command
{
	NSSet *existingMappingItemsForOtherControls = [self existingMappingItemsForRespondersOtherThanCurrentForCommand:command];
	
	if ([existingMappingItemsForOtherControls count]) {
		MIKMIDIMappingGeneratorRemapBehavior behavior = MIKMIDIMappingGeneratorRemapDefault;
		if ([self.delegate respondsToSelector:@selector(mappingGenerator:behaviorForRemappingControlMappedWithItems:toNewResponder:commandIdentifier:)]) {
			behavior = [self.delegate mappingGenerator:self
			behaviorForRemappingControlMappedWithItems:existingMappingItemsForOtherControls
										toNewResponder:self.controlBeingLearned
									 commandIdentifier:self.commandIdentifierBeingLearned];
		}
		
		switch (behavior) {
			default:
			case MIKMIDIMappingGeneratorRemapDisallow:
				return; // Ignore this command
				break;
			case MIKMIDIMappingGeneratorRemapAllowDuplicate:
				// Do nothing special
				break;
			case MIKMIDIMappingGeneratorRemapReplace:
				// Remove the existing mapping items.
				[self.mapping removeMappingItems:existingMappingItemsForOtherControls];
				break;
		}
	}
	
	if ([self.receivedMessages count]) {
		// If we get a message from a different controller number, channel,
		// or command type (not counting note on vs note off), restart the mapping
		
		BOOL allowTouchSenseMessages = NO;
		
		// Ignore different message types if we're trying to map a knob,
		// since they sometimes send note on/off commands for touch sensing.
		if (self.responderTypeOfControlBeingLearned & MIKMIDIResponderTypeKnob &&
			[self.receivedMessages count] > [self defaultMinimumNumberOfMessagesRequiredForResponderType:self.responderTypeOfControlBeingLearned]) {
			allowTouchSenseMessages = YES;
		}
		
		MIKMIDIChannelVoiceCommand *firstMessage = [self.receivedMessages objectAtIndex:0];
		BOOL firstMessageIsDifferent = ![self command:firstMessage isSameTypeChannelNumberAsCommand:command];
		if (!allowTouchSenseMessages && firstMessageIsDifferent) {
			[self.receivedMessages removeAllObjects];
		}
	}
	
	if (![self.controlBeingLearned respondsToMIDICommand:command]) return;
	
	[self.receivedMessages addObject:command];
	self.messagesTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutInteveral
																 target:self
															   selector:@selector(timeoutTimerFired:)
															   userInfo:nil
																repeats:NO];
	
	if ([self.receivedMessages count] > self.numMessagesRequired) { // Don't try to finish unless we've received several messages (eg. from a knob) already
		MIKMIDIMappingItem *mappingItem = [self mappingItemForCommandIdentifier:self.commandIdentifierBeingLearned
																	  inControl:self.controlBeingLearned
														   fromReceivedMessages:self.receivedMessages];
		if (mappingItem) [self finishMappingItem:mappingItem error:nil];
	}
}

#pragma mark Messages to Mapping Item

- (BOOL)fillInButtonMappingItem:(MIKMIDIMappingItem **)mappingItem fromMessages:(NSArray *)messages
{
	if (![messages count]) return NO;
	if ([messages count] > 2) return NO;
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	
	MIKMIDIMappingItem *result = *mappingItem;
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIControlNumberFromCommand(firstMessage);
	
	// Tap type button
	if ([messages count] == 1) {
		if ([[NSDate date] timeIntervalSinceDate:firstMessage.timestamp] < self.timeoutInteveral) return NO; // Need to keep waiting for another message
		
		result.interactionType = MIKMIDIResponderTypePressButton;
	}
	
	// Key type button
	if ([messages count] == 2) {
		MIKMIDIChannelVoiceCommand *secondMessage = [messages objectAtIndex:1];
		BOOL firstIsZero = MIKMIDIControlValueFromChannelVoiceCommand(firstMessage) == 0 || firstMessage.commandType == MIKMIDICommandTypeNoteOff;
		BOOL secondIsZero = MIKMIDIControlValueFromChannelVoiceCommand(secondMessage) == 0 || secondMessage.commandType == MIKMIDICommandTypeNoteOff;
		
		result.interactionType = (!firstIsZero && secondIsZero) ? MIKMIDIResponderTypePressReleaseButton : MIKMIDIResponderTypePressButton;
	}
	
	return YES;
}

- (BOOL)fillInRelativeKnobMappingItem:(MIKMIDIMappingItem **)mappingItem fromMessages:(NSArray *)messages
{
	if ([messages count] < [self defaultMinimumNumberOfMessagesRequiredForResponderType:MIKMIDIResponderTypeRelativeKnob]) return NO;
	
	// Disallow non-control change messages
	for (MIKMIDIChannelVoiceCommand *message in messages) { if (message.commandType != MIKMIDICommandTypeControlChange) return NO; }
	
	NSMutableSet *messageValues = [NSMutableSet set];
	for (MIKMIDIChannelVoiceCommand *message in messages) {
		[messageValues addObject:@(MIKMIDIControlValueFromChannelVoiceCommand(message))];
	}
	// If there are more than 2 message values, it's more likely an absolute knob.
	if ([messages count] == [messageValues count] || [messageValues count] > 2) return NO;
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	
	MIKMIDIMappingItem *result = *mappingItem;
	result.interactionType = MIKMIDIResponderTypeRelativeKnob;
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIControlNumberFromCommand(firstMessage);
	result.flipped = ([(MIKMIDIChannelVoiceCommand *)[messages lastObject] value] < 64);
	return YES;
}

- (BOOL)fillInTurntableKnobMappingItem:(MIKMIDIMappingItem **)mappingItem fromMessages:(NSArray *)messages
{
	// Filter non-control change messages
	NSPredicate *controlChangePredicate = [NSPredicate predicateWithFormat:@"commandType == %@", @(MIKMIDICommandTypeControlChange)];
	messages = [messages filteredArrayUsingPredicate:controlChangePredicate];
	
	if ([messages count] < [self defaultMinimumNumberOfMessagesRequiredForResponderType:MIKMIDIResponderTypeTurntableKnob]) return NO;
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	
	MIKMIDIMappingItem *result = *mappingItem;
	result.interactionType = MIKMIDIResponderTypeTurntableKnob;
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIControlNumberFromCommand(firstMessage);
	result.flipped = ([(MIKMIDIChannelVoiceCommand *)[messages lastObject] value] < 64);
	return YES;
}

- (BOOL)fillInAbsoluteKnobSliderMappingItem:(MIKMIDIMappingItem **)mappingItem fromMessages:(NSArray *)messages
{
	if ([messages count] < [self defaultMinimumNumberOfMessagesRequiredForResponderType:MIKMIDIResponderTypeAbsoluteSliderOrKnob]) return NO;
	
	// Disallow non-control change messages
	for (MIKMIDIChannelVoiceCommand *message in messages) { if (message.commandType != MIKMIDICommandTypeControlChange) return NO; }
	
	MIKMIDIChannelVoiceCommand *firstMessage = [messages objectAtIndex:0];
	MIKMIDIMappingItem *result = *mappingItem;
	result.interactionType = MIKMIDIResponderTypeAbsoluteSliderOrKnob;
	result.channel = firstMessage.channel;
	result.controlNumber = MIKMIDIControlNumberFromCommand(firstMessage);
	
	// Figure out which direction it goes
	NSInteger directionCounter = 0;
	MIKMIDIChannelVoiceCommand *previousMessage = (MIKMIDIChannelVoiceCommand *)firstMessage;
	for (MIKMIDIChannelVoiceCommand *message in messages) {
		if (MIKMIDIControlValueFromChannelVoiceCommand(message) > MIKMIDIControlValueFromChannelVoiceCommand(previousMessage)) directionCounter++;
		if (MIKMIDIControlValueFromChannelVoiceCommand(message) < MIKMIDIControlValueFromChannelVoiceCommand(previousMessage)) directionCounter--;
		previousMessage = message;
	}
	result.flipped = (directionCounter < 0);
	
	return YES;
}

- (BOOL)fillInRelativeAbsoluteKnobSliderMappingItem:(MIKMIDIMappingItem **)mappingItem fromMessages:(NSArray *)messages
{
	for (MIKMIDICommand *message in messages) {
		if ([message respondsToSelector:@selector(isFourteenBitCommand)] &&
			[(MIKMIDIControlChangeCommand *)message isFourteenBitCommand]) {
			// For now, we're assuming that controllers don't do this with 14 bit commands
			return NO;
		}
	}
	
	if (![self fillInAbsoluteKnobSliderMappingItem:mappingItem fromMessages:messages]) return NO;
	
	// Determine if it's a "fake" absolute knob by looking at the time between messages, velocity,
	// and whether the value increases by exactly one each time.
	NSTimeInterval medianTimeBetweenMessages = 0;
	NSMutableArray *timesBetweenMessages = [NSMutableArray array];
	double totalValueChange = 0;
	MIKMIDIChannelVoiceCommand *previousMessage = nil;
	for (MIKMIDIChannelVoiceCommand *message in messages) {
		if (previousMessage) {
			totalValueChange += fabs(MIKMIDIControlValueFromChannelVoiceCommand(message) - MIKMIDIControlValueFromChannelVoiceCommand(previousMessage));
			[timesBetweenMessages addObject:@([message.timestamp timeIntervalSinceDate:previousMessage.timestamp])];
		}
		previousMessage = message;
	}
	[timesBetweenMessages sortUsingSelector:@selector(compare:)];
	medianTimeBetweenMessages = [[timesBetweenMessages objectAtIndex:([timesBetweenMessages count] / 2)] doubleValue];
	double valueChangePerMessage = totalValueChange / (double)([messages count] - 1);
	
	// If we see a big value change per message (>1.2) we assume it's a real absolute knob, despite
	// other indicators. This is because some controllers throttle the messages coming from a absolute knobs so the
	// time between messages is long, but there's a big value change for each message.
	if (valueChangePerMessage > 1.1) return NO;
	
	// If the time between messages is short, it's probably not a relative absolute knob either.
	if (medianTimeBetweenMessages < 0.02) return NO;
	
	[*mappingItem setInteractionType:MIKMIDIResponderTypeRelativeAbsoluteKnob];
	
	return YES;
}

- (MIKMIDIMappingItem *)mappingItemForCommandIdentifier:(NSString *)commandID inControl:(id<MIKMIDIMappableResponder>)responder fromReceivedMessages:(NSArray *)messages
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
	
	MIKMIDIResponderType responderType = [responder MIDIResponderTypeForCommandIdentifier:commandID];
	
	MIKMIDIMappingItem *result = [[MIKMIDIMappingItem alloc] initWithMIDIResponderIdentifier:[responder MIDIIdentifier] andCommandIdentifier:commandID];
	
	if (responderType & MIKMIDIResponderTypeButton &&
		[self fillInButtonMappingItem:&result fromMessages:messages]) {
		goto FINALIZE_RESULT_AND_RETURN;
	}
	
	if (responderType & MIKMIDIResponderTypeTurntableKnob &&
		[self fillInTurntableKnobMappingItem:&result fromMessages:messages]) {
		goto FINALIZE_RESULT_AND_RETURN;
	}
	
	if (responderType & MIKMIDIResponderTypeRelativeKnob &&
		[self fillInRelativeKnobMappingItem:&result fromMessages:messages]) {
		goto FINALIZE_RESULT_AND_RETURN;
	}
	
	if (responderType & MIKMIDIResponderTypeRelativeAbsoluteKnob &&
		[self fillInRelativeAbsoluteKnobSliderMappingItem:&result fromMessages:messages]) {
		goto FINALIZE_RESULT_AND_RETURN;
	}
	
	if (responderType & MIKMIDIResponderTypeAbsoluteSliderOrKnob &&
		[self fillInAbsoluteKnobSliderMappingItem:&result fromMessages:messages]) {
		goto FINALIZE_RESULT_AND_RETURN;
	}
	
	return nil;
	
FINALIZE_RESULT_AND_RETURN:
	result.commandType = [messages[0] commandType];
	
	return result;
}

- (void)timeoutTimerFired:(NSTimer *)timer
{
	MIKMIDIMappingItem *mappingItem = [self mappingItemForCommandIdentifier:self.commandIdentifierBeingLearned
																  inControl:self.controlBeingLearned
													   fromReceivedMessages:self.receivedMessages];
	if (mappingItem) {
		[self finishMappingItem:mappingItem error:nil];
	} else {
		// Start over listening
		[self.receivedMessages removeAllObjects];
	}
}

- (void)finishMappingItem:(MIKMIDIMappingItem *)mappingItemOrNil error:(NSError *)errorOrNil
{
	MIKMIDIMappingGeneratorMappingCompletionBlock completionBlock = self.currentMappingCompletionBlock;
	
	self.currentMappingCompletionBlock = nil;
	self.controlBeingLearned = nil;
	NSArray *receivedMessages = [self.receivedMessages copy];
	[self.receivedMessages removeAllObjects];
	self.messagesTimeoutTimer = nil;
	
	if (mappingItemOrNil) [self.mapping addMappingItemsObject:mappingItemOrNil];
	if (completionBlock) completionBlock(mappingItemOrNil, receivedMessages, errorOrNil);
}

#pragma mark Utility

- (NSUInteger)defaultMinimumNumberOfMessagesRequiredForResponderType:(MIKMIDIResponderType)responderType
{
	if (responderType & MIKMIDIResponderTypeTurntableKnob) return 50;
	if (responderType & MIKMIDIResponderTypeAbsoluteSliderOrKnob) return 5;
	return 3;
}

- (BOOL)command:(MIKMIDIChannelVoiceCommand *)command1 isSameTypeChannelNumberAsCommand:(MIKMIDIChannelVoiceCommand *)command2
{
	if (command1.channel != command2.channel) return NO;
	if (MIKMIDIControlNumberFromCommand(command1) != MIKMIDIControlNumberFromCommand(command2)) return NO;
	
	BOOL isDifferentCommandType = command1.commandType != command2.commandType;
	BOOL areNoteCommands = (command1.commandType == MIKMIDICommandTypeNoteOn || command1.commandType == MIKMIDICommandTypeNoteOff) &&
	(command2.commandType == MIKMIDICommandTypeNoteOn || command2.commandType == MIKMIDICommandTypeNoteOff);
	isDifferentCommandType &= !areNoteCommands;
	if (isDifferentCommandType) return NO;
	
	return YES;
}

- (NSSet *)existingMappingItemsForRespondersOtherThanCurrentForCommand:(MIKMIDIChannelVoiceCommand *)command
{
	if (!command) return [NSMutableSet set];
	
	NSSet *existingMappingItems = [self.mapping mappingItemsForMIDICommand:command];
	NSMutableSet *result = [existingMappingItems mutableCopy];
	if ([self.commandIdentifierBeingLearned length] && self.controlBeingLearned) {
		NSSet *existingForCurrentResponder = [self.mapping mappingItemsForCommandIdentifier:self.commandIdentifierBeingLearned responder:self.controlBeingLearned];
		[result minusSet:existingForCurrentResponder];
	}
	return result;
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
	if (![sources count]) {
		NSString *description = NSLocalizedString(@"MIDI Device has no sources", @"MIDI Device has no sources");
		*error = [NSError MIKMIDIErrorWithCode:MIKMIDIDeviceHasNoSourcesErrorCode userInfo:@{NSLocalizedDescriptionKey: description}];
		return NO;
	}
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	
	MIKMIDIDeviceManager *manager = [MIKMIDIDeviceManager sharedDeviceManager];
	__weak MIKMIDIMappingGenerator *weakSelf = self;
	id connectionToken = [manager connectInput:source error:error eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
		for (MIKMIDICommand *command in commands) {
			if (![command isKindOfClass:[MIKMIDIChannelVoiceCommand class]]) continue;
			[weakSelf handleMIDICommand:(MIKMIDIChannelVoiceCommand *)command];
		}
	}];
	self.connectionToken = connectionToken;
	return connectionToken != nil;
}

- (void)disconnectFromDevice
{
	NSArray *sources = [self.device.entities valueForKeyPath:@"@unionOfArrays.sources"];
	if (![sources count]) return;
	MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
	[[MIKMIDIDeviceManager sharedDeviceManager] disconnectInput:source forConnectionToken:self.connectionToken];
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
