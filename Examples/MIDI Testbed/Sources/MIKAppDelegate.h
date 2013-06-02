//
//  MIKAppDelegate.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 3/7/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class MIKMIDIDeviceManager;
@class MIKMIDIDevice;

@interface MIKAppDelegate : NSObject <NSApplicationDelegate>

- (IBAction)ledCheckboxChanged:(id)sender;
- (IBAction)flash:(id)sender;

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) IBOutlet NSTextView *textView;
@property (nonatomic, strong) MIKMIDIDeviceManager *midiDeviceManager;
@property (nonatomic, strong) MIKMIDIDevice *device;

@end
