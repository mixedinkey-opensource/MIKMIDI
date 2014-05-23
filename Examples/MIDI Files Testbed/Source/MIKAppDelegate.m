//
//  MIKAppDelegate.m
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKAppDelegate.h"
#import "MIKMIDISequence.h"
#import "MIKMIDITrackView.h"

@implementation MIKAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	// Insert code here to initialize your application
}

- (IBAction)loadFile:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setAllowsMultipleSelection:NO];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowedFileTypes:@[@"mid", @"midi"]];
	[openPanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
		if (result != NSFileHandlingPanelOKButton) return;
		
		NSError *error = nil;
		MIKMIDISequence *sequence = [MIKMIDISequence sequenceWithFileAtURL:[openPanel URL] error:&error];
		if (!sequence) {
			NSLog(@"Error loading MIDI file: %@", error);
		} else {
			NSLog(@"Loaded MIDI file: %@", sequence);
			self.trackView.track = [sequence.tracks firstObject];
		}
	}];
}
@end
