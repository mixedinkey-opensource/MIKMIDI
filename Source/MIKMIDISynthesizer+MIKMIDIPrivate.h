//
//  MIKMIDISynthesizer_SubclassMethods.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/26/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDISynthesizer.h"
#import "MIKMIDICompilerCompatibility.h"

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDISynthesizer ()

- (BOOL)startGraphWithError:(NSError **)error;
- (BOOL)stopGraphWithError:(NSError **)error;

@property (nonatomic, readonly, getter=isGraphRunning) BOOL graphRunning;

@end

NS_ASSUME_NONNULL_END
