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

typedef void(^MIKMIDIMappingGeneratorMappingCompletionBlock)(MIKMIDIMappingItem *mappingItem, NSError *error);


@interface MIKMIDIMappingGenerator : NSObject

+ (instancetype)mappingGeneratorWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;
- (instancetype)initWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;

- (void)learnMappingForControl:(id<MIKMIDIMappableResponder>)control
		 withCommandIdentifier:(NSString *)commandID
			   completionBlock:(MIKMIDIMappingGeneratorMappingCompletionBlock)completionBlock;
- (void)cancelCurrentCommandLearning;

// Properties

@property (nonatomic, strong) MIKMIDIDevice *device;
@property (nonatomic, strong) MIKMIDIMapping *mapping; // Assign before mapping starts to modify existing mapping

@end
