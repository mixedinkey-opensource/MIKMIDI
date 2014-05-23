//
//  MIKMIDITrackView.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDITrackView.h"
#import "MIKMIDITrack.h"
#import "MIKMIDIEvent.h"
#import "MIKMIDINoteEvent.h"

@implementation MIKMIDITrackView

- (void)drawRect:(NSRect)dirtyRect
{
	CGFloat ppt = [self pixelsPerTick];
	CGFloat noteHeight = [self pixelsPerNote];
	for (MIKMIDINoteEvent *note in [self.track events]) {
		if (note.eventType != kMusicEventType_MIDINoteMessage) continue;
		
		CGFloat yPosition = NSMinY([self bounds]) + note.note * [self pixelsPerNote];
		NSRect noteRect = NSMakeRect(NSMinX([self bounds]) + note.musicTimeStamp * ppt, yPosition, note.duration * ppt, noteHeight);
		
		[[self colorForNote:note] setFill];
		[[NSColor blackColor] setStroke];
		NSBezierPath *path = [NSBezierPath bezierPathWithRect:noteRect];
		[path fill];
		[path stroke];
	}
}

#pragma mark - Private

- (NSColor *)colorForNote:(MIKMIDINoteEvent *)note
{
	NSArray	*colors = @[[NSColor redColor], [NSColor orangeColor], [NSColor yellowColor], [NSColor greenColor], [NSColor blueColor], [NSColor purpleColor]];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:colors];
	return [gradient interpolatedColorAtLocation:(CGFloat)(note.note % 12) / 12.0];
}

- (CGFloat)pixelsPerTick
{
	return NSWidth([self bounds]) / self.track.length;
}

- (CGFloat)pixelsPerNote
{
	return NSHeight([self bounds]) / 127.0;
}

#pragma mark - Properties

- (void)setTrack:(MIKMIDITrack *)track
{
	if (track != _track) {
		_track = track;
		[self setNeedsDisplay:YES];
	}
}

@end
