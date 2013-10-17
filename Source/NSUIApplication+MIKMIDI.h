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

/**
 *  Define MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS as a non-zero value to (re)enable searching
 *  the view hierarchy for MIDI responders. This is disabled by default because it's slow.
 */
//#define MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS 0

@protocol MIKMIDIResponder;

@class MIKMIDICommand;

@interface MIK_APPLICATION_CLASS (MIKMIDI)

/**
 *  Register a MIDI responder for receipt of incoming MIDI messages.
 *
 *  The application maintains a zeroing weak reference to the responder, so unregistering the responder on deallocate is not necessary.
 *
 *  @param responder The responder to register.
 */
- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder;

/**
 *  Unregister a previously-registered MIDI responder so it stops receiving incoming MIDI messages.
 *
 *  @param responder The responder to unregister.
 */
- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder;

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
- (NSSet *)allMIDIResponders;

@end
