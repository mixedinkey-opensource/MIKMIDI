//
//  MIKMIDIMapping.h
//  Energetic
//
//  Created by Andrew Madsen on 3/15/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MIKMIDICommand.h"
#import "MIKMIDIResponder.h"

@protocol MIKMIDIMappableResponder;

@class MIKMIDIChannelVoiceCommand;
@class MIKMIDIMappingItem;

@interface MIKMIDIMapping : NSObject

#if !TARGET_OS_IPHONE
- (instancetype)initWithFileAtURL:(NSURL *)url error:(NSError **)error;
- (instancetype)initWithFileAtURL:(NSURL *)url;
- (instancetype)initWithXMLDocument:(NSXMLDocument *)xmlDocument;
- (NSXMLDocument *)XMLRepresentation;
- (BOOL)writeToFileAtURL:(NSURL *)fileURL error:(NSError **)error;
#endif

- (NSSet *)mappingItemsForMIDIResponder:(id<MIKMIDIMappableResponder>)responder;
- (NSSet *)mappingItemsForCommandIdentifier:(NSString *)identifier responder:(id<MIKMIDIMappableResponder>)responder;
- (NSSet *)mappingItemsForMIDICommand:(MIKMIDIChannelVoiceCommand *)command;

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *controllerName;
@property (nonatomic, readonly) NSSet *mappingItems;
- (void)addMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;
- (void)addMappingItems:(NSSet *)mappingItems;
- (void)removeMappingItemsObject:(MIKMIDIMappingItem *)mappingItem;
- (void)removeMappingItems:(NSSet *)mappingItems;

@end

@interface MIKMIDIMappingItem : NSObject

- (instancetype)initWithMIDIResponderIdentifier:(NSString *)MIDIResponderIdentifier andCommandIdentifier:(NSString *)commandIdentifier;

#if !TARGET_OS_IPHONE
- (instancetype)initWithXMLElement:(NSXMLElement *)element;
- (NSXMLElement *)XMLRepresentation;
#endif

// Properties

@property (nonatomic, readonly) NSString *MIDIResponderIdentifier;
@property (nonatomic, readonly) NSString *commandIdentifier;
@property (nonatomic) MIKMIDIResponderType interactionType;
@property (nonatomic, getter = isFlipped) BOOL flipped; // If yes, value decreases as slider/knob goes left->right or top->bottom
@property (nonatomic) NSInteger channel;
@property (nonatomic) MIKMIDICommandType commandType;
@property (nonatomic) NSUInteger controlNumber;

/**
 *  Optional additional key value pairs, which will be saved as attributes in this item's XML representation. Keys and values must be NSStrings.
 */
@property (nonatomic, copy) NSDictionary *additionalAttributes;

@end

NSUInteger MIKMIDIMappingControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command);
float MIKMIDIMappingControlValueFromCommand(MIKMIDIChannelVoiceCommand *command);

@protocol MIKMIDIMappableResponder <MIKMIDIResponder>

@required
- (NSArray *)commandIdentifiers;
- (MIKMIDIResponderType)MIDIResponderTypeForCommandIdentifier:(NSString *)commandID; // Optional. If not implemented, MIKMIDIResponderTypeAll will be assumed.

@end