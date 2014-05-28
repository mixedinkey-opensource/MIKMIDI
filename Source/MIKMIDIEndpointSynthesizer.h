//
//  MIKMIDIEndpointSynthesizer.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 5/27/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDISourceEndpoint;

@interface MIKMIDIEndpointSynthesizer : NSObject

+ (instancetype)playerWithMIDISource:(MIKMIDISourceEndpoint *)source;

- (instancetype)initWithMIDISource:(MIKMIDISourceEndpoint *)source;

@property (nonatomic, strong, readonly) MIKMIDISourceEndpoint *source;

@end
