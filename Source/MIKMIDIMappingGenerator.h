//
//  MIKMIDIMappingGenerator.h
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDIDevice;
@class MIKMIDIMapping;
@class MIKMIDIMappingItem;
@protocol MIKMIDIResponder;

typedef void(^MIKMIDIMappingGeneratorMappingCompletionBlock)(MIKMIDIMappingItem *mappingItem, NSError *error);


@interface MIKMIDIMappingGenerator : NSObject

+ (instancetype)mappingGeneratorWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;
- (instancetype)initWithDevice:(MIKMIDIDevice *)device error:(NSError **)error;

- (void)learnMappingForControl:(id<MIKMIDIResponder>)control completionBlock:(MIKMIDIMappingGeneratorMappingCompletionBlock)completionBlock;

// Properties

@property (nonatomic, strong) MIKMIDIDevice *device;
@property (nonatomic, strong, readonly) MIKMIDIMapping *mapping;

@end
