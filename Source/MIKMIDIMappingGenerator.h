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

@property (nonatomic, strong) MIKMIDIDevice *device;

/**
 *  The mapping being generated. Assign before mapping starts to modify existing mapping.
 */
@property (nonatomic, strong) MIKMIDIMapping *mapping;

@end
