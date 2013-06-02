//
//  NSApplication+MIKMIDI.h
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#if !TARGET_OS_IPHONE
#import <Cocoa/Cocoa.h>

@protocol MIKMIDIResponder;

@class MIKMIDICommand;

@interface NSApplication (MIKMIDI)

- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder;
- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder;

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

@end
#endif