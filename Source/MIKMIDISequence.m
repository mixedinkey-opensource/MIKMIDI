//
//  MIKMIDISequence.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequence.h"
#import <AudioToolbox/AudioToolbox.h>
#import "MIKMIDITrack.h"

@interface MIKMIDISequence ()

@property (nonatomic, strong, readwrite) MIKMIDITrack *tempoTrack;
@property (nonatomic, strong, readwrite) NSArray *tracks;

@end

@implementation MIKMIDISequence
{
	MusicSequence _musicSequence;
}

+ (instancetype)sequenceWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
	return [[self alloc] initWithFileAtURL:fileURL error:error];
}

- (instancetype)initWithFileAtURL:(NSURL *)fileURL error:(NSError **)error;
{
	error = error ? error : &(NSError *__autoreleasing){ nil };
	self = [super init];
	if (self) {
		OSStatus err = NewMusicSequence(&_musicSequence);
		if (err) {
			NSLog(@"Unable to create MusicSequence: %i", err);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return nil;
		}
		
		err = MusicSequenceFileLoad(_musicSequence, (__bridge CFURLRef)fileURL, 0, kMusicSequenceLoadSMF_ChannelsToTracks);
		if (err) {
			NSLog(@"Unable to load MIDI file %@: %i", fileURL, err);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return nil;
		}		
	}
	return self;
}



- (instancetype)init
{
    return [self initWithFileAtURL:nil error:NULL];
}

- (void)dealloc
{
    for (MIKMIDITrack *track in self.tracks) {
		[track cleanup];
	}
	self.tracks = nil;
	[self.tempoTrack cleanup];
	self.tempoTrack = nil;
}

#pragma mark - Properties

@end
