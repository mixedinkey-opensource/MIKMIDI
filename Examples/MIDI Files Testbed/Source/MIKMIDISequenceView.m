//
//  MIKMIDITrackView.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequenceView.h"
#import "MIKMIDISequence.h"
#import "MIKMIDITrack.h"
#import "MIKMIDIEvent.h"
#import "MIKMIDINoteEvent.h"

@implementation MIKMIDISequenceView

- (void)drawRect:(NSRect)dirtyRect
{
	CGFloat ppt = [self pixelsPerTick];
	CGFloat noteHeight = [self pixelsPerNote];
	NSInteger index=0;
	for (MIKMIDITrack *track in self.sequence.tracks) {
		[[self colorForTrackAtIndex:index++] setFill];
		[[NSColor blackColor] setStroke];
		
		for (MIKMIDINoteEvent *note in [track events]) {
			if (note.eventType != kMusicEventType_MIDINoteMessage) continue;
			
			CGFloat yPosition = NSMinY([self bounds]) + note.note * [self pixelsPerNote];
			NSRect noteRect = NSMakeRect(NSMinX([self bounds]) + note.musicTimeStamp * ppt, yPosition, note.duration * ppt, noteHeight);
			
			NSBezierPath *path = [NSBezierPath bezierPathWithRect:noteRect];
			[path fill];
			[path stroke];
		}
	}
}

#pragma mark - Private

- (NSColor *)colorForNote:(MIKMIDINoteEvent *)note
{
	NSArray	*colors = @[[NSColor redColor], [NSColor orangeColor], [NSColor yellowColor], [NSColor greenColor], [NSColor blueColor], [NSColor purpleColor]];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:colors];
	return [gradient interpolatedColorAtLocation:(CGFloat)(note.note % 12) / 12.0];
}

- (NSColor *)colorForTrackAtIndex:(NSInteger)index
{
	NSArray	*colors = @[[NSColor redColor], [NSColor orangeColor], [NSColor yellowColor], [NSColor greenColor], [NSColor blueColor], [NSColor purpleColor]];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:colors];
	return [gradient interpolatedColorAtLocation:index / (float)[self.sequence.tracks count]];
}

- (CGFloat)pixelsPerTick
{
	double maxLength = [[self.sequence valueForKeyPath:@"tracks.@max.length"] doubleValue];
	return NSWidth([self bounds]) / maxLength;
}

- (CGFloat)pixelsPerNote
{
	return NSHeight([self bounds]) / 127.0;
}

#pragma mark - Properties

- (void)setSequence:(MIKMIDISequence *)sequence
{
	if (sequence != _sequence) {
		_sequence = sequence;
		[self setNeedsDisplay:YES];
	}
}

@end
