//
//  MIKMIDIMapping.m
//  Energetic
//
//  Created by Andrew Madsen on 3/15/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMapping.h"
#import "MIKMIDICommand.h"
#import "MIKMIDIChannelVoiceCommand.h"
#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDINoteOnCommand.h"
#import "MIKMIDINoteOffCommand.h"
#import "MIKMIDIPrivateUtilities.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMapping.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMapping.m in the Build Phases for this target
#endif

@interface MIKMIDIMappingItem ()

#if !TARGET_OS_IPHONE
- (instancetype)initWithXMLElement:(NSXMLElement *)element;
- (NSXMLElement *)XMLRepresentation;
#endif

@end

@interface MIKMIDIMapping ()

@property (nonatomic, readwrite, getter = isBundledMapping) BOOL bundledMapping;
@property (nonatomic, strong) NSMutableSet *internalMappingItems;

@end

@implementation MIKMIDIMapping

#if !TARGET_OS_IPHONE

- (instancetype)initWithFileAtURL:(NSURL *)url
{
	return [self initWithFileAtURL:url error:NULL];
}

- (instancetype)initWithFileAtURL:(NSURL *)url error:(NSError **)error;
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:error];
	if (!xmlDocument) {
		NSLog(@"Unable to read MIDI map XML file at %@: %@", url, *error);
		self = nil;
		return nil;
	}
	self = [self initWithXMLDocument:xmlDocument];
	if (self) {
		if (![_name length]) _name = [[url lastPathComponent] stringByDeletingPathExtension];
	}
	return self;
}

- (instancetype)initWithXMLDocument:(NSXMLDocument *)xmlDocument
{
	self = [self init];
	if (self) {
		if (![self loadPropertiesFromXMLDocument:xmlDocument]) {
			self = nil;
			return nil;
		}
	}
	return self;
}

#endif

- (id)init
{
    self = [super init];
    if (self) {
        self.internalMappingItems = [NSMutableSet set];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIMapping *result = [[[self class] alloc] init];
	result.name = self.name;
	result.controllerName = self.controllerName;
	result.bundledMapping = self.bundledMapping;
	result.additionalAttributes = self.additionalAttributes;
	
	for (MIKMIDIMappingItem *item in self.mappingItems) {
		[result addMappingItemsObject:[item copy]];
	}
	
	return result;
}

#if !TARGET_OS_IPHONE
- (NSXMLDocument *)XMLRepresentation;
{
	NSXMLElement *controllerName = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[controllerName setName:@"ControllerName"];
	[controllerName setStringValue:self.controllerName];
	NSXMLElement *mappingName = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[mappingName setName:@"MappingName"];
	[mappingName setStringValue:self.name];
	
	NSSortDescriptor *sortByResponderID = [NSSortDescriptor sortDescriptorWithKey:@"MIDIResponderIdentifier" ascending:YES];
	NSSortDescriptor *sortByCommandID = [NSSortDescriptor sortDescriptorWithKey:@"commandIdentifier" ascending:YES];
	NSArray *sortedMappingItems = [self.mappingItems sortedArrayUsingDescriptors:@[sortByResponderID, sortByCommandID]];
	NSArray *mappingItemXMLElements = [sortedMappingItems valueForKey:@"XMLRepresentation"];
	NSXMLElement *mappingItems = [NSXMLElement elementWithName:@"MappingItems" children:mappingItemXMLElements attributes:nil];
	
	NSMutableArray *attributes = [NSMutableArray arrayWithArray:@[mappingName, controllerName]];
	for (NSString *key in self.additionalAttributes) {
		NSXMLElement *attributeElement = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
		NSString *stringValue = self.additionalAttributes[key];
		if (![stringValue isKindOfClass:[NSString class]]) {
			NSLog(@"Ignoring additional attribute %@ : %@ because it is not a string.", key, stringValue);
			continue;
		}
		[attributeElement setName:key];
		[attributeElement setStringValue:stringValue];
		[attributes addObject:attributeElement];
	}
	
	NSXMLElement *rootElement = [NSXMLElement elementWithName:@"Mapping"
													 children:@[mappingItems]
												   attributes:attributes];
	
	NSXMLDocument *result = [[NSXMLDocument alloc] initWithRootElement:rootElement];
	[result setVersion:@"1.0"];
	[result setCharacterEncoding:@"UTF-8"];
	return result;
}

- (BOOL)writeToFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	NSData *mappingXMLData = [[self XMLRepresentation] XMLDataWithOptions:NSXMLNodePrettyPrint];
	if (![mappingXMLData writeToURL:fileURL options:NSDataWritingAtomic error:error]) {
		NSLog(@"Error saving MIDI mapping %@ to %@: %@", self.name, fileURL, *error);
		return NO;
	}
	return YES;
}

#endif

- (BOOL)isEqual:(MIKMIDIMapping *)otherMapping
{
	if (self == otherMapping) return YES;
	if (![self.name isEqualToString:otherMapping.name]) return NO;
	if (![self.controllerName isEqualToString:otherMapping.controllerName]) return NO;
	
	return [self.mappingItems isEqualToSet:otherMapping.mappingItems];
}

- (NSUInteger)hash
{
	NSUInteger result = [self.name hash];
	result += [self.controllerName hash];
	
	for (MIKMIDIMappingItem *mappingItem in self.mappingItems) {
		result += [mappingItem hash];
	}
	
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ for %@ Mapping Items: %@", [super description], self.name, self.controllerName, self.mappingItems];
}

- (NSSet *)mappingItemsForMIDIResponder:(id<MIKMIDIMappableResponder>)responder;
{
	NSPredicate *commandPredicate = [NSPredicate predicateWithFormat:@"commandIdentifier IN %@", [responder commandIdentifiers]];
	NSPredicate *responderPredicate = [NSPredicate predicateWithFormat:@"MIDIResponderIdentifier LIKE %@", [responder MIDIIdentifier]];
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[commandPredicate, responderPredicate]];
	NSSet *matches = [self.mappingItems filteredSetUsingPredicate:predicate];
	return matches;
}

- (NSSet *)mappingItemsForCommandIdentifier:(NSString *)identifier responder:(id<MIKMIDIMappableResponder>)responder;
{
	NSPredicate *commandPredicate = [NSPredicate predicateWithFormat:@"commandIdentifier LIKE %@", identifier];
	NSPredicate *responderPredicate = [NSPredicate predicateWithFormat:@"MIDIResponderIdentifier LIKE %@", [responder MIDIIdentifier]];
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[commandPredicate, responderPredicate]];
	NSSet *matches = [self.mappingItems filteredSetUsingPredicate:predicate];
	return matches;
}

- (NSSet *)mappingItemsForMIDICommand:(MIKMIDIChannelVoiceCommand *)command;
{
	NSUInteger controlNumber = MIKMIDIControlNumberFromCommand(command);
	UInt8 channel = command.channel;
	MIKMIDICommandType commandType = command.commandType;
	
	NSPredicate *controlNumberPredicate = [NSPredicate predicateWithFormat:@"controlNumber == %@", @(controlNumber)];
	NSPredicate *channelPredicate = [NSPredicate predicateWithFormat:@"channel == %@", @(channel)];
	NSPredicate *commandTypePredicate = [NSPredicate predicateWithFormat:@"commandType == %@", @(commandType)];
	NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[controlNumberPredicate, channelPredicate, commandTypePredicate]];
	NSSet *matches = [self.mappingItems filteredSetUsingPredicate:predicate];
	return matches;
}

#pragma mark - Private

#if !TARGET_OS_IPHONE
- (BOOL)loadPropertiesFromXMLDocument:(NSXMLDocument *)xmlDocument
{
	NSError *error = nil;
	
	NSArray *mappings = [xmlDocument nodesForXPath:@"./Mapping" error:&error];
	if (![mappings count]) {
		NSLog(@"Unable to get mapping from MIDI Mapping XML: %@", error);
		return NO;
	}
	NSXMLElement *mapping = [mappings lastObject];
	
	NSArray *nameAttributes = [mapping nodesForXPath:@"./@MappingName" error:&error];
	if (!nameAttributes) NSLog(@"Unable to get name attributes from MIDI Mapping XML: %@", error);
	self.name = [[nameAttributes lastObject] stringValue];
	
	NSArray *controllerNameAttributes = [mapping nodesForXPath:@"./@ControllerName" error:&error];
	if (!controllerNameAttributes) NSLog(@"Unable to get controller name attributes from MIDI Mapping XML: %@", error);
	self.controllerName = [[controllerNameAttributes lastObject] stringValue];
	
	NSArray *mappingItemElements = [mapping nodesForXPath:@"./MappingItems/MappingItem" error:&error];
	if (!mappingItemElements) {
		NSLog(@"Unable to get mapping items from MIDI mapping XML: %@", error);
		return NO;
	}
	
	for (NSXMLElement *element in mappingItemElements) {
		MIKMIDIMappingItem *item = [[MIKMIDIMappingItem alloc] initWithXMLElement:element];
		if (!item) continue;
		[self.internalMappingItems addObject:item];
	}
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	for (NSXMLNode *attribute in [mapping attributes]) {
		if (![[attribute stringValue] length]) continue;
		if ([[attribute name] isEqualToString:@"MappingName"]) continue;
		if ([[attribute name] isEqualToString:@"ControllerName"]) continue;
		[attributes setObject:[attribute stringValue] forKey:[attribute name]];
	}
	self.additionalAttributes = attributes;
	
	return YES;
}
#endif

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"mappingItems"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalMappingItems"];
	}
	
	if ([key isEqualToString:@"name"]) {
		keyPaths = [keyPaths setByAddingObject:@"controllerName"];
	}
	
	return keyPaths;
}

- (NSSet *)mappingItems { return [self.internalMappingItems copy]; }

- (void)addMappingItemsObject:(MIKMIDIMappingItem *)mappingItem
{
	[self.internalMappingItems addObject:mappingItem];
}

- (void)addMappingItems:(NSSet *)mappingItems
{
	[self.internalMappingItems unionSet:mappingItems];
}

- (void)removeMappingItemsObject:(MIKMIDIMappingItem *)mappingItem
{
	[self.internalMappingItems removeObject:mappingItem];
}

- (void)removeMappingItems:(NSSet *)mappingItems
{
	[self.internalMappingItems minusSet:mappingItems];
}

- (NSString *)name
{
	if (![_name length]) return self.controllerName;
	return _name;
}

@end

#pragma mark -

@implementation MIKMIDIMappingItem

- (instancetype)initWithMIDIResponderIdentifier:(NSString *)MIDIResponderIdentifier andCommandIdentifier:(NSString *)commandIdentifier;
{
	self = [super init];
	
	if (self) {
		_MIDIResponderIdentifier = [MIDIResponderIdentifier copy];
		_commandIdentifier = [commandIdentifier copy];
	}
	
	return self;
}

- (id)init
{
	[NSException raise:NSInternalInconsistencyException format:@"-[MIKMIDIMappingItem init] is deprecated and should be replaced with a call to -initWithMIDIResponderIdentifier:andCommandIdentifier:."];
    return [self initWithMIDIResponderIdentifier:@"Unknown" andCommandIdentifier:@"Unknown"];
}

#if !TARGET_OS_IPHONE
- (instancetype)initWithXMLElement:(NSXMLElement *)element;
{
	if (!element) { self = nil; return self; }
	
	NSError *error = nil;
	
	NSXMLElement *responderIdentifier = [[element nodesForXPath:@"ResponderIdentifier" error:&error] lastObject];
	if (!responderIdentifier) {
		NSLog(@"Unable to read responder identifier from %@: %@", element, error);
		self = nil;
		return nil;
	}
	
	NSXMLElement *commandIdentifier = [[element nodesForXPath:@"CommandIdentifier" error:&error] lastObject];
	if (!commandIdentifier) {
		NSLog(@"Unable to read command identifier from %@: %@", element, error);
		self = nil;
		return nil;
	}
	
	NSXMLElement *channel = [[element nodesForXPath:@"Channel" error:&error] lastObject];
	if (!channel) {
		NSLog(@"Unable to read channel from %@: %@", element, error);
		self = nil;
		return nil;
	}
	
	NSXMLElement *commandType = [[element nodesForXPath:@"CommandType" error:&error] lastObject];
	if (!commandType) {
		NSLog(@"Unable to read command type from %@: %@", element, error);
	}
	
	NSXMLElement *controlNumber = [[element nodesForXPath:@"ControlNumber" error:&error] lastObject];
	if (!controlNumber) {
		NSLog(@"Unable to read control number from %@: %@", element, error);
		self = nil;
		return nil;
	}
	
	NSXMLElement *interactionType = [[element nodesForXPath:@"@InteractionType" error:&error] lastObject];
	if (!interactionType) {
		NSLog(@"Unable to read interaction type from %@: %@", element, error);
		self = nil;
		return nil;
	}
	
	NSXMLElement *flippedStatus = [[element nodesForXPath:@"@Flipped" error:&error] lastObject];
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	for (NSXMLNode *attribute in [element attributes]) {
		if (![[attribute stringValue] length]) continue;
		if ([[attribute name] isEqualToString:@"InteractionType"]) continue;
		if ([[attribute name] isEqualToString:@"Flipped"]) continue;
		[attributes setObject:[attribute stringValue] forKey:[attribute name]];
	}
	
	self = [self initWithMIDIResponderIdentifier:[responderIdentifier stringValue] andCommandIdentifier:[commandIdentifier stringValue]];
	if (self) {
		_channel = [[channel stringValue] integerValue];
		_commandType = [[commandType stringValue] integerValue];
		_controlNumber = [[controlNumber stringValue] integerValue];
		_interactionType = [self interactionTypeForString:[interactionType stringValue]];
		_flipped = [[flippedStatus stringValue] boolValue];
		
		_additionalAttributes = [attributes copy];
	}
	return self;
}

- (NSXMLElement *)XMLRepresentation;
{
	NSXMLElement *responderIdentifier = [NSXMLElement elementWithName:@"ResponderIdentifier" stringValue:self.MIDIResponderIdentifier];
	NSXMLElement *commandIdentifier = [NSXMLElement elementWithName:@"CommandIdentifier" stringValue:self.commandIdentifier];
	NSXMLElement *channel = [NSXMLElement elementWithName:@"Channel"];
	[channel setStringValue:[@(self.channel) stringValue]];
	NSXMLElement *commandType = [NSXMLElement elementWithName:@"CommandType"];
	[commandType setStringValue:[@(self.commandType) stringValue]];
	NSXMLElement *controlNumber = [NSXMLElement elementWithName:@"ControlNumber"];
	[controlNumber setStringValue:[@(self.controlNumber) stringValue]];
	
	NSXMLElement *interactionType = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[interactionType setName:@"InteractionType"];
	NSString *interactionTypeString = [self stringForInteractionType:self.interactionType];
	[interactionType setStringValue:interactionTypeString];
	
	NSXMLElement *flippedStatus = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[flippedStatus setName:@"Flipped"];
	NSString *flippedStatusString = self.flipped ? @"true" : @"false";
	[flippedStatus setStringValue:flippedStatusString];
	
	NSMutableArray *attributes = [NSMutableArray arrayWithArray:@[interactionType, flippedStatus]];
	for (NSString *key in self.additionalAttributes) {
		NSXMLElement *attributeElement = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
		NSString *stringValue = self.additionalAttributes[key];
		if (![stringValue isKindOfClass:[NSString class]]) {
			NSLog(@"Ignoring additional attribute %@ : %@ because it is not a string.", key, stringValue);
			continue;
		}
		[attributeElement setName:key];
		[attributeElement setStringValue:stringValue];
		[attributes addObject:attributeElement];
	}
	
	return [NSXMLElement elementWithName:@"MappingItem"
								children:@[responderIdentifier, commandIdentifier, channel, commandType, controlNumber]
							  attributes:attributes];
}
#endif

- (id)copyWithZone:(NSZone *)zone
{
	MIKMIDIMappingItem *result = [[MIKMIDIMappingItem alloc] initWithMIDIResponderIdentifier:self.MIDIResponderIdentifier andCommandIdentifier:self.commandIdentifier];
	result.interactionType = self.interactionType;
	result.flipped = self.flipped;
	result.channel = self.channel;
	result.commandType = self.commandType;
	result.controlNumber = self.controlNumber;
	result.additionalAttributes = self.additionalAttributes;
	
	return result;
}

- (BOOL)isEqual:(MIKMIDIMappingItem *)otherMappingItem
{
	if (self == otherMappingItem) return YES;
	
	if (self.controlNumber != otherMappingItem.controlNumber) return NO;
	if (self.channel != otherMappingItem.channel) return NO;
	if (self.commandType != otherMappingItem.commandType) return NO;
	if (self.interactionType != otherMappingItem.interactionType) return NO;
	if (self.flipped != otherMappingItem.flipped) return NO;
	if (![self.MIDIResponderIdentifier isEqualToString:otherMappingItem.MIDIResponderIdentifier]) return NO;
	if (![self.commandIdentifier isEqualToString:otherMappingItem.commandIdentifier]) return NO;
	if (![self.additionalAttributes isEqualToDictionary:otherMappingItem.additionalAttributes]) return NO;
	
	return YES;
}

- (NSUInteger)hash
{
	// Only depend on non-mutable properties
	NSUInteger result = [_MIDIResponderIdentifier hash];
	result += [_commandIdentifier hash];
	
	return result;
}

- (NSString *)description
{
	NSMutableString *result = [NSMutableString stringWithFormat:@"%@ %@ %@ CommandID: %@ Channel %li MIDI Command %li Control Number %lu flipped %i", [super description], [self stringForInteractionType:self.interactionType], self.MIDIResponderIdentifier, self.commandIdentifier, (long)self.channel, (long)self.commandType, (unsigned long)self.controlNumber, (int)self.flipped];
	if ([self.additionalAttributes count]) {
		for (NSString *key in self.additionalAttributes) {
			NSString *value = self.additionalAttributes[key];
			[result appendFormat:@" %@: %@", key, value];
		}
	}
	return result;
}

#pragma mark - Public

#pragma mark - Private

- (NSString *)stringForInteractionType:(MIKMIDIResponderType)type
{
	NSDictionary *map = @{@(MIKMIDIResponderTypePressReleaseButton) : @"Key",
						  @(MIKMIDIResponderTypePressButton) : @"Tap",
						  @(MIKMIDIResponderTypeAbsoluteSliderOrKnob) : @"KnobSlider",
						  @(MIKMIDIResponderTypeRelativeKnob) : @"JogWheel",
						  @(MIKMIDIResponderTypeTurntableKnob) : @"TurnTable",
						  @(MIKMIDIResponderTypeRelativeAbsoluteKnob) : @"RelativeAbsoluteKnob"};
	return [map objectForKey:@(type)];
}

- (MIKMIDIResponderType)interactionTypeForString:(NSString *)string
{
	NSDictionary *map = @{@"Key" : @(MIKMIDIResponderTypePressReleaseButton),
						  @"Tap" : @(MIKMIDIResponderTypePressButton),
						  @"KnobSlider" : @(MIKMIDIResponderTypeAbsoluteSliderOrKnob),
						  @"JogWheel" : @(MIKMIDIResponderTypeRelativeKnob),
						  @"TurnTable" : @(MIKMIDIResponderTypeTurntableKnob),
						  @"RelativeAbsoluteKnob" : @(MIKMIDIResponderTypeRelativeAbsoluteKnob)};
	return [[map objectForKey:string] integerValue];
}

#pragma mark - Properties

@end
