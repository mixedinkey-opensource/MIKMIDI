//
//  NSApplication+MIKMIDI.h
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#if TARGET_OS_IPHONE

	#import <UIKit/UIKit.h>
	#define MIK_APPLICATION_CLASS UIApplication
	#define MIK_WINDOW_CLASS UIWindow
	#define MIK_VIEW_CLASS UIView

#else

	#import <Cocoa/Cocoa.h>
	#define MIK_APPLICATION_CLASS NSApplication
	#define MIK_WINDOW_CLASS NSWindow
	#define MIK_VIEW_CLASS NSView

#endif

@protocol MIKMIDIResponder;

@class MIKMIDICommand;

@interface MIK_APPLICATION_CLASS (MIKMIDI)

- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder;
- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder;

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
- (NSSet *)allMIDIResponders;

@end
