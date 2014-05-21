//
//  MIKMIDISequence.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDITrack;

@interface MIKMIDISequence : NSObject

+ (instancetype)sequenceWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
- (instancetype)initWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;

@property (nonatomic, strong, readonly) MIKMIDITrack *tempoTrack;
@property (nonatomic, strong, readonly) NSArray *tracks;

@end
