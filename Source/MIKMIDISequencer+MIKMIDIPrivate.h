//
//  MIKMIDISequencer+MIKMIDIPrivate.h
//  MIKMIDI
//
//  Created by Chris Flesner on 6/30/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDI.h>
#import "MIKMIDICompilerCompatibility.h"

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDISequencer (MIKMIDIPrivate)

- (void)dispatchSyncToProcessingQueueAsNeeded:(void (^)())block;

@end

NS_ASSUME_NONNULL_END