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
		
		
		// Get tempo track
		MusicTrack tempoTrack;
		err = MusicSequenceGetTempoTrack(_musicSequence, &tempoTrack);
		if (err) {
			NSLog(@"Unable to get tempo track from MIDI file %@: %i", fileURL, err);
		} else {
			self.tempoTrack = [[MIKMIDITrack alloc] initWithMusicTrack:tempoTrack];
		}
		
		// Get music tracks
		UInt32 numTracks = 0;
		err = MusicSequenceGetTrackCount(_musicSequence, &numTracks);
		if (err) {
			NSLog(@"Unable to get number of tracks in MIDI file %@: %i", fileURL, err);
			*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
			return nil;
		}
		
		NSMutableArray *tracks = [NSMutableArray array];
		for (UInt32 i=0; i<numTracks; i++) {
			MusicTrack musicTrack;
			err = MusicSequenceGetIndTrack(_musicSequence, i, &musicTrack);
			if (err) {
				NSLog(@"Unable to get track %lu in MIDI file %@: %i", (unsigned long)i, fileURL, err);
				*error = [NSError errorWithDomain:NSPOSIXErrorDomain code:err userInfo:nil];
				return nil;
			}
			
			MIKMIDITrack *track = [[MIKMIDITrack alloc] initWithMusicTrack:musicTrack];
			if (track) [tracks addObject:track];
		}
		self.tracks = tracks;
	}
	return self;
}

- (instancetype)init
{
    return [self initWithFileAtURL:nil error:NULL];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ tempo track: %@ tracks: %@", [super description], self.tempoTrack, self.tracks];
}

#pragma mark - Properties

@end
