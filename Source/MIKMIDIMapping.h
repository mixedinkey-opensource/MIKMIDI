;;//
//  MIKMIDIMapping.h
//  Energetic
//
//  Created by Andrew Madsen on 3/15/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MIKMIDICommand.h"
#import "MIKMIDIResponder.h"

@class MIKMIDIChannelVoiceCommand;
@class MIKMIDIMappingItem;

@interface MIKMIDIMapping : NSObject

#if !TARGET_OS_IPHONE
- (instancetype)initWithFileAtURL:(NSURL *)url;
- (instancetype)initWithXMLDocument:(NSXMLDocument *)xmlDocument;
- (NSXMLDocument *)XMLRepresentation;
#endif

- (NSSet *)mappingItemsForCommandIdentifier:(NSString *)identifier;
- (MIKMIDIMappingItem *)mappingItemForControlNumber:(NSUInteger)controlNumber;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *controllerName;
@property (nonatomic, readonly) NSSet *mappingItems;
- (void)addMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;
- (void)removeMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;

@end

@interface MIKMIDIMappingItem : NSObject

#if !TARGET_OS_IPHONE
- (instancetype)initWithXMLElement:(NSXMLElement *)element;
- (NSXMLElement *)XMLRepresentation;
#endif

// Properties

@property (nonatomic) MIKMIDIResponderType interactionType;
@property (nonatomic, getter = isFlipped) BOOL flipped; // If yes, value decreases as slider/knob goes left->right or top->bottom
@property (nonatomic, copy) NSString *commandIdentifier;
@property (nonatomic) NSInteger channel;
@property (nonatomic) MIKMIDICommandType commandType;
@property (nonatomic) NSUInteger controlNumber;

@end

NSUInteger MIKMIDIMappingControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command);