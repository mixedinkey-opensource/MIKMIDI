//
//  MIKAppDelegate.h
//  MIDI Files Testbed
//
//  Created by Andrew Madsen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIKMIDITrackView;

@interface MIKAppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)loadFile:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (weak) IBOutlet MIKMIDITrackView *trackView;

@end
