//
//  MIKMIDIMapping.m
//  Energetic
//
//  Created by Andrew Madsen on 3/15/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMapping.h"
#import "MIKMIDI.h"

@interface MIKMIDIMapping ()

@property (nonatomic, strong) NSMutableSet *internalMappingItems;

@end

@implementation MIKMIDIMapping

- (instancetype)initWithFileAtURL:(NSURL *)url
{
	NSError *error = nil;
	NSXMLDocument *xmlDocument = [[NSXMLDocument alloc] initWithContentsOfURL:url options:0 error:&error];
	if (!xmlDocument) {
		NSLog(@"Unable to read MIDI map XML file at %@: %@", url, error);
		self = nil;
		return nil;
	}
	self = [self initWithXMLDocument:xmlDocument];
	if (self) {
		
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

- (id)init
{
    self = [super init];
    if (self) {
        self.internalMappingItems = [NSMutableSet set];
    }
    return self;
}

- (NSXMLDocument *)XMLRepresentation;
{
	NSXMLElement *controllerName = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[controllerName setName:@"ControllerName"];
	[controllerName setStringValue:self.controllerName];
	NSXMLElement *mappingName = [[NSXMLElement alloc] initWithKind:NSXMLAttributeKind];
	[mappingName setName:@"MappingName"];
	[mappingName setStringValue:self.name];
	
	NSArray *mappingItemXMLElements = [[self.mappingItems valueForKey:@"XMLRepresentation"] allObjects];
	NSXMLElement *mappingItems = [NSXMLElement elementWithName:@"MappingItems" children:mappingItemXMLElements attributes:nil];
	NSXMLElement *rootElement = [NSXMLElement elementWithName:@"Mapping"
													 children:@[mappingItems]
												   attributes:@[mappingName, controllerName]];
	
	NSXMLDocument *result = [[NSXMLDocument alloc] initWithRootElement:rootElement];
	[result setVersion:@"1.0"];
	[result setCharacterEncoding:@"UTF-8"];
	return result;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ for %@ Mapping Items: %@", [super description], self.name, self.controllerName, self.mappingItems];
}

- (MIKMIDIMappingItem *)mappingItemForCommandIdentifier:(NSString *)identifier;
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"commandIdentifier LIKE %@", identifier];
	NSSet *matches = [self.mappingItems filteredSetUsingPredicate:predicate];
	return [matches anyObject];
}

- (MIKMIDIMappingItem *)mappingItemForControlNumber:(NSUInteger)controlNumber;
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"controlNumber == %@", @(controlNumber)];
	NSSet *matches = [self.mappingItems filteredSetUsingPredicate:predicate];
	return [matches anyObject];
}

#pragma mark - Private

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
	
	return YES;
}

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

- (void)removeMappingItemsObject:(MIKMIDIMappingItem *)mappingItem
{
	[self.internalMappingItems removeObject:mappingItem];
}

- (NSString *)name { return self.controllerName; } // Temporary (when remmoving, also remove KVO dependency)

@end

#pragma mark -

@implementation MIKMIDIMappingItem

- (instancetype)initWithXMLElement:(NSXMLElement *)element;
{
	self = [self init];
	if (self) {
		NSError *error = nil;
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
		
		self.commandIdentifier = [commandIdentifier stringValue];
		self.channel = [[channel stringValue] integerValue];
		self.commandType = [[commandType stringValue] integerValue];
		self.controlNumber = [[controlNumber stringValue] integerValue];
		self.interactionType = [self interactionTypeForString:[interactionType stringValue]];
		self.flipped = ([[flippedStatus stringValue] boolValue] != 0);
	}
	return self;
}

- (NSXMLElement *)XMLRepresentation;
{
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
	NSString *flippedStatusString = self.flipped ? @"Yes" : @"No";
	[flippedStatus setStringValue:flippedStatusString];
	
	return [NSXMLElement elementWithName:@"MappingItem"
								children:@[commandIdentifier, channel, commandType, controlNumber]
							  attributes:@[interactionType, flippedStatus]];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ %@ Channel %li Command %li Control Number %lu flipped %i", [super description], [self stringForInteractionType:self.interactionType], self.commandIdentifier, (long)self.channel, (long)self.commandType, (unsigned long)self.controlNumber, (int)self.flipped];
}

#pragma mark - Public

#pragma mark - Private

- (NSString *)stringForInteractionType:(MIKMIDIMappingInteractionType)type
{
	NSDictionary *map = @{@(MIKMIDIMappingInteractionTypeKey) : @"Key",
					   @(MIKMIDIMappingInteractionTypeTap) : @"Tap",
					   @(MIKMIDIMappingInteractionTypeAbsoluteKnobSlider) : @"KnobSlider",
					   @(MIKMIDIMappingInteractionTypeJogWheel) : @"JogWheel"};
	return [map objectForKey:@(type)];
}

- (MIKMIDIMappingInteractionType)interactionTypeForString:(NSString *)string
{
	NSDictionary *map = @{@"Key" : @(MIKMIDIMappingInteractionTypeKey),
					   @"Tap" : @(MIKMIDIMappingInteractionTypeTap),
					   @"KnobSlider" : @(MIKMIDIMappingInteractionTypeAbsoluteKnobSlider),
					   @"JogWheel" : @(MIKMIDIMappingInteractionTypeJogWheel)};
	return [[map objectForKey:string] integerValue];
}

#pragma mark - Properties

@end

NSUInteger MIKMIDIMappingControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command)
{
	if ([command respondsToSelector:@selector(controllerNumber)]) return [(id)command controllerNumber];
	if ([command respondsToSelector:@selector(note)]) return [(MIKMIDINoteOnCommand *)command note];
	
	return (command.dataByte1 & 0x7F);
}