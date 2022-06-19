//
//  MIKMIDITempoTrack.h
//  MIKMIDI
//
//  Created by Andrew R Madsen on 12/15/19.
//  Copyright © 2019 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MIKMIDI/MIKMIDITrack.h>
#import <MIKMIDI/MIKMIDICompilerCompatibility.h>

@class MIKMIDITempoEvent;

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDITempoTrack : MIKMIDITrack

@property (nonatomic, strong, readonly) MIKArrayOf(MIKMIDITempoEvent *) *tempoEvents;

@end

NS_ASSUME_NONNULL_END
