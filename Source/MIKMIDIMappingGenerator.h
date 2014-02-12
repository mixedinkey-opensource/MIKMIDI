//
//  MIKMIDIMappingGenerator.h
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "MIKMIDIMapping.h"

@class MIKMIDIDevice;
@class MIKMIDIMapping;
@class MIKMIDIMappingItem;

@protocol MIKMIDIMappingGeneratorDelegate;

/**
 *  Completion block for mapping generation method.
 *
 *  @param mappingItem The mapping item generated, or nil if mapping failed.
 *  @param messages    The messages used to generate the mapping. May not include all messages received during mapping.
 *  @param error       If mapping failed, an NSError explaing the failure, nil if mapping succeeded.
 */

typedef void(^MIKMIDIMappingGeneratorMappingCompletionBlock)(MIKMIDIMappingItem *mappingItem, NSArray *messages, NSError *error);

@interface MIKMIDIMappingGenerator : NSObject

+ (instancetype)mappingGeneratorWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;
- (instancetype)initWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;

/**
 *  Begins mapping a given MIDIResponder. This method returns immediately.
 *
 *  @param control         The MIDI Responder object to map. Must conform to the MIKMIDIMappableResponder protocol.
 *  @param commandID       The command identifier to be mapped. Must be one of the identifiers returned by the responder's -commandIdentifiers method.
 *  @param numMessages     The minimum number of messages to receive before immediately mapping the control. Pass 0 for the default.
 *  @param timeout         Time to wait (in seconds) after the last received message before attempting to generate a mapping, or start over. Pass 0 for the default.
 *  @param completionBlock Block called when mapping is successfully completed. Call -cancelCurrentCommandLearning to cancel a failed mapping.
 */
- (void)learnMappingForControl:(id<MIKMIDIMappableResponder>)control
		 withCommandIdentifier:(NSString *)commandID
	 requiringNumberOfMessages:(NSUInteger)numMessages
			 orTimeoutInterval:(NSTimeInterval)timeout
			   completionBlock:(MIKMIDIMappingGeneratorMappingCompletionBlock)completionBlock;

/**
 *  Cancels the mapping previously started by calling -learnMappingForControl:withCommandIdentifier:requiringNumberOfMessages:orTimeoutInterval:completionBlock:.
 */
- (void)cancelCurrentCommandLearning;

// Properties

/**
 * The delegate for the mapping generator. Can be used to customize certain mapping behavior. Optional.
 *
 * The delegate must implement the MIKMIDIMappingGeneratorDelegate protocol.
 *
 */
@property (nonatomic, unsafe_unretained) id<MIKMIDIMappingGeneratorDelegate> delegate;

/**
 *  The device for which a mapping is being generated. Must not be nil.
 */
@property (nonatomic, strong) MIKMIDIDevice *device;

/**
 *  The mapping being generated. Assign before mapping starts to modify existing mapping.
 */
@property (nonatomic, strong) MIKMIDIMapping *mapping;

@end


/**
 *  Possible values to return from the following methods in MIKMIDIMappingGeneratorDelegate:
 *
 *  -mappingGenerator:behaviorForRemappingCommandMappedToControls:toNewControl:
 *
 */
typedef NS_ENUM(NSUInteger, MIKMIDIMappingGeneratorRemapBehavior) {
	
	/**
	 *  Ignore the previously mapped control, and do not (re)map it to the responder for which mapping is in progress.
	 */
	MIKMIDIMappingGeneratorRemapDisallow,
	
	/**
	 *  Map the previously mapped control to the responder for which mapping is in progress. Do not remove the previous/existing
	 *  mappings for the control.
	 */
	MIKMIDIMappingGeneratorRemapAllowDuplicate,
	
	/**
	 *  Map the previously mapped control to the responder for which mapping is in progress. Remove the previous/existing
	 *  mappings for the control. With this option, after mapping, only the newly-mapped responder will be associated with the
	 *  mapped physical control.
	 */
	MIKMIDIMappingGeneratorRemapReplace,
	
	/**
	 * The default behavior which is MIKMIDIMappingGeneratorRemapDisallow.
	 */
	MIKMIDIMappingGeneratorRemapDefault = MIKMIDIMappingGeneratorRemapDisallow,
};

@protocol MIKMIDIMappingGeneratorDelegate <NSObject>

@optional

/**
 *  Used to determine behavior when attempting to map a physical control that has been previously mapped to a new responder.
 *
 *  When MIKMIDIMappingGenerator receives mappable messages from a physical control and finds that that control has already
 *  been mapped to one or more other virtual controls (responder/command combinations), it will call this method to ask what
 *  to do. One of the options specified in MIKMIDIMappingGeneratorRemapBehavior should be returned.
 *
 *  To use the default behavior, (currently MIKMIDIMappingGeneratorRemapDisallow) return MIKMIDIMappingGeneratorRemapDefault. If the
 *  delegate does not respond to this method, the default behavior is used.
 *
 *  @param generator         The mapping generator performing the mapping.
 *  @param mappingItems      The mapping items for commands previously mapped to the physical control in question.
 *  @param newResponder      The responder for which a mapping is currently being generated.
 *  @param commandIdentifier The command identifier of newResponder that is being mapped.
 *
 *  @return The behavior to use when mapping the newResponder. See MIKMIDIMappingGeneratorRemapBehavior for a list of possible values.
 */
- (MIKMIDIMappingGeneratorRemapBehavior)mappingGenerator:(MIKMIDIMappingGenerator *)generator
			  behaviorForRemappingControlMappedWithItems:(NSSet *)mappingItems
										  toNewResponder:(id<MIKMIDIMappableResponder>)newResponder
									   commandIdentifier:(NSString *)commandIdentifier;

/**
 *  Used to determine whether the existing mapping item for a responder should be superceded by a new mapping item.
 *
 *  The default behavior is to remove existing mapping items (return value of YES). If the delegate does not respond to
 *  this method, the default behavior is used.
 *
 *  @param generator    The mapping generator performing the mapping.
 *  @param mappingItems The set of existing MIKMIDIMappingItems associated with responder.
 *  @param responder    The reponsder for which a mapping is currently being generated.
 *
 *  @return YES to remove the existing mapping items. NO to keep the existing mapping items in addition to the new mapping item being generated.
 */
- (BOOL)mappingGenerator:(MIKMIDIMappingGenerator *)generator
shouldRemoveExistingMappingItems:(NSSet *)mappingItems
 forResponderBeingMapped:(id<MIKMIDIMappableResponder>)responder;

@end