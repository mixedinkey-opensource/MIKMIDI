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
 *
 *  @deprecated This feature still works, but its use is discouraged. It is deprecated and may be removed in the future.
 */
//#define MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS 0

@protocol MIKMIDIResponder;

@class MIKMIDICommand;

/**
 *  MIKMIDI implements a category on NSApplication (on OS X) or UIApplication (on iOS)
 *  to facilitate the creation and use of a MIDI responder hierarchy, along with the ability
 *  to send MIDI commands to responders in that hierarchy.
 */
@interface MIK_APPLICATION_CLASS (MIKMIDI)

/**
 *  Register a MIDI responder for receipt of incoming MIDI messages.
 *
 *  If targeting OS X 10.8 or higher, or iOS, the application maintains a zeroing weak
 *  reference to the responder, so unregistering the responder on deallocate is not necessary.
 *
 *  For applications targeting OS X 10.7, registered responders must be explicitly
 *  unregistered (e.g. in their -dealloc method) by calling -unregisterMIDIResponder before
 *  being deallocated.
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

/**
 *  NSApplication (OS X) or UIApplication (iOS) itself implements to methods in the MIKMIDIResponder protocol.
 *  This method determines if any responder in the MIDI responder chain (registered responders and their subresponders)
 *  responds to the passed in MIDI command, and returns YES if so.
 *
 *  @param command An MIKMIDICommand instance.
 *
 *  @return YES if any registered MIDI responder responds to the command.
 */
- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;

/**
 *  <#Description#>
 *
 *  @param command <#command description#>
 */
- (void)handleMIDICommand:(MIKMIDICommand *)command;

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
- (NSSet *)allMIDIResponders;

@end
