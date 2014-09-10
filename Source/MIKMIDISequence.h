//
//  MIKMIDISequence.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>


@class MIKMIDITrack;

@interface MIKMIDISequence : NSObject

+ (instancetype)sequence;

+ (instancetype)sequenceWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
- (instancetype)initWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;

+ (instancetype)sequenceWithData:(NSData *)data;
- (instancetype)initWithData:(NSData *)data;

- (BOOL)writeToURL:(NSURL *)fileURL error:(NSError **)error;

- (MIKMIDITrack *)createNewTrack;
- (BOOL)removeTrack:(MIKMIDITrack *)track;

@property (nonatomic, readonly) MIKMIDITrack *tempoTrack;
@property (nonatomic, readonly) NSArray *tracks;

@property (nonatomic, readonly) MusicSequence musicSequence;

@property (nonatomic, readonly) MusicTimeStamp length;
@property (nonatomic, readonly) Float64 durationInSeconds;

@property (nonatomic, readonly) NSData *dataValue;

@end
