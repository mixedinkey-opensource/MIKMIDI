//
//  MIKMIDITrackView.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDISequenceView.h"
#import <MIKMIDI/MIKMIDI.h>

void * MIKMIDISequenceViewKVOContext = &MIKMIDISequenceViewKVOContext;

@interface MIKMIDISequenceView ()

@property (nonatomic) BOOL dragInProgress;

@end

@implementation MIKMIDISequenceView

- (instancetype)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self registerForDraggedTypes:@[NSFilenamesPboardType]];
    }
    return self;
}

- (void)dealloc
{
	self.sequence = nil;
}

#pragma mark - Layout

- (NSSize)intrinsicContentSize
{
	double maxLength = [[self.sequence valueForKeyPath:@"tracks.@max.length"] doubleValue];
	return NSMakeSize(maxLength * [self pixelsPerTick], 250.0);
}

#pragma mark - Drawing

- (void)drawRect:(NSRect)dirtyRect
{
	if (self.dragInProgress) {
		[[NSColor lightGrayColor] set];
		NSRectFill([self bounds]);
	}
	
	CGFloat ppt = [self pixelsPerTick];
	CGFloat noteHeight = [self pixelsPerNote];
	NSInteger index=0;
	for (MIKMIDITrack *track in self.sequence.tracks) {
		
		for (MIKMIDINoteEvent *note in [track notes]) {
			NSColor *noteColor = [self.sequence.tracks count] < 2 ? [self colorForNote:note] : [self colorForTrackAtIndex:index];
			
			[[NSColor blackColor] setStroke];
			[noteColor setFill];
			
			CGFloat yPosition = NSMinY([self bounds]) + note.note * [self pixelsPerNote];
			NSRect noteRect = NSMakeRect(NSMinX([self bounds]) + note.timeStamp * ppt, yPosition, note.duration * ppt, noteHeight);
			
			NSBezierPath *path = [NSBezierPath bezierPathWithRect:noteRect];
			[path fill];
			[path stroke];
		}
		index++;
	}
}

#pragma mark - NSDraggingDestination

- (NSArray *)MIDIFilesFromPasteboard:(NSPasteboard *)pb
{
	if (![[pb types] containsObject:NSFilenamesPboardType]) return NSDragOperationNone;
	
	NSArray *files = [pb propertyListForType:NSFilenamesPboardType];
	files = [files filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(NSString *file, NSDictionary *bindings) {
		return [[file pathExtension] isEqualToString:@"mid"] || [[file pathExtension] isEqualToString:@"midi"];
	}]];
	return files;
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender
{
	NSArray *files = [self MIDIFilesFromPasteboard:[sender draggingPasteboard]];
	self.dragInProgress = [files count] != 0;
	return [files count] ? NSDragOperationCopy : NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender
{
	self.dragInProgress = NO;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender
{
	NSArray *files = [self MIDIFilesFromPasteboard:[sender draggingPasteboard]];
	if (![files count]) return NO;
	
	if ([self.delegate respondsToSelector:@selector(midiSequenceView:receivedDroppedMIDIFiles:)]) {
		[self.delegate midiSequenceView:self receivedDroppedMIDIFiles:files];
	}
	
	return YES;
}

- (void)concludeDragOperation:(id<NSDraggingInfo>)sender
{
	self.dragInProgress = NO;
}

#pragma mark - Private

- (NSColor *)colorForNote:(MIKMIDINoteEvent *)note
{
	NSArray	*colors = @[[NSColor redColor], [NSColor orangeColor], [NSColor yellowColor], [NSColor greenColor], [NSColor blueColor], [NSColor purpleColor]];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:colors];
	CGFloat notePosition = (CGFloat)(note.note % 12) / 12.0;
	return [gradient interpolatedColorAtLocation:notePosition];
}

- (NSColor *)colorForTrackAtIndex:(NSInteger)index
{
	NSArray	*colors = @[[NSColor redColor], [NSColor orangeColor], [NSColor yellowColor], [NSColor greenColor], [NSColor blueColor], [NSColor purpleColor]];
	NSGradient *gradient = [[NSGradient alloc] initWithColors:colors];
	return [gradient interpolatedColorAtLocation:index / (float)[self.sequence.tracks count]];
}

- (CGFloat)pixelsPerTick
{
	return 15.0;
}

- (CGFloat)pixelsPerNote
{
	return NSHeight([self bounds]) / 127.0;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context != MIKMIDISequenceViewKVOContext) {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
		return;
	}
	
	if ([keyPath isEqualToString:@"length"]) {
		[self invalidateIntrinsicContentSize];
	}
	
	if ([keyPath isEqualToString:@"tracks"]) {
		[self unregisterForKVOOnTracks:change[NSKeyValueChangeOldKey]];
		[self registerForKVOOnTracks:change[NSKeyValueChangeNewKey]];
		
		[self setNeedsDisplay:YES];
	}
	
	if ([object isKindOfClass:[MIKMIDITrack class]]) {
		[self invalidateIntrinsicContentSize];
		[self setNeedsDisplay:YES];
	}
}

- (void)registerForKVOOnTracks:(NSArray *)tracks
{
	for (MIKMIDITrack *track in tracks) {
		[track addObserver:self forKeyPath:@"events" options:0 context:MIKMIDISequenceViewKVOContext];
	}
}

- (void)unregisterForKVOOnTracks:(NSArray *)tracks
{
	for (MIKMIDITrack *track in tracks) {
		[track removeObserver:self forKeyPath:@"events"];
	}
}

#pragma mark - Properties

- (void)setSequence:(MIKMIDISequence *)sequence
{
	if (sequence != _sequence) {
		
		[_sequence removeObserver:self forKeyPath:@"length"];
		[_sequence removeObserver:self forKeyPath:@"tracks"];
		[self unregisterForKVOOnTracks:_sequence.tracks];
		
		_sequence = sequence;
		
		[_sequence addObserver:self forKeyPath:@"length" options:NSKeyValueObservingOptionInitial context:MIKMIDISequenceViewKVOContext];
		NSKeyValueObservingOptions options = NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew;
		[_sequence addObserver:self forKeyPath:@"tracks" options:options context:MIKMIDISequenceViewKVOContext];
		if (_sequence) [self registerForKVOOnTracks:_sequence.tracks];
	}
}

- (void)setDragInProgress:(BOOL)dragInProgress
{
	if (dragInProgress != _dragInProgress) {
		_dragInProgress = dragInProgress;
		[self setNeedsDisplay:YES];
	}
}

@end
