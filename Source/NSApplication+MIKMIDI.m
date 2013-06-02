//
//  NSApplication+MIKMIDI.m
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//
#if !TARGET_OS_IPHONE

#import "NSApplication+MIKMIDI.h"
#import "MIKMIDIResponder.h"
#import "MIKMIDICommand.h"

@interface NSView (MIKSubviews)
- (NSSet *)mik_allSubviews; // returns all subviews in flat set
@end



static BOOL MIKObjectRespondsToMIDICommand(id object, MIKMIDICommand *command)
{
	if (!object) return NO;
	return [object conformsToProtocol:@protocol(MIKMIDIResponder)] && [(id<MIKMIDIResponder>)object respondsToMIDICommand:command];
}

@implementation NSApplication (MIKMIDI)

+(NSHashTable *)registeredMIKMIDIResponders
{
    static NSHashTable *registeredMIKMIDIResponders = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		NSPointerFunctionsOptions options = NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality;
		registeredMIKMIDIResponders = [[NSHashTable alloc] initWithOptions:options capacity:0];
	});
    return registeredMIKMIDIResponders;
}

- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder;
{
	[[[self class] registeredMIKMIDIResponders] addObject:responder];
}

- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder;
{
	[[[self class] registeredMIKMIDIResponders] removeObject:responder];
}

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
{
	return [[self respondersForMIDICommand:command] count] != 0;
}

- (void)handleMIDICommand:(MIKMIDICommand *)command;
{
	for (id<MIKMIDIResponder> responder in [self respondersForMIDICommand:command]) {
		[responder handleMIDICommand:command];
	}
}

#pragma mark - Private

- (NSSet *)respondersForMIDICommand:(MIKMIDICommand *)command
{
	NSMutableSet *result = [NSMutableSet set];
	
	// Go through the entire view hierarchy
	for (NSWindow *window in [self windows]) {
		if (MIKObjectRespondsToMIDICommand(window, command)) [result addObject:window];
		if (MIKObjectRespondsToMIDICommand([window delegate], command)) [result addObject:[window delegate]];
		if (MIKObjectRespondsToMIDICommand([window windowController], command)) [result addObject:[window windowController]];
		for (NSView *subview in [[window contentView] mik_allSubviews]) {
			if (MIKObjectRespondsToMIDICommand(subview, command)) [result addObject:subview];
		}
	}
	
	// Go through registered responders
	for (id<MIKMIDIResponder> responder in [[self class] registeredMIKMIDIResponders]) {
		if (MIKObjectRespondsToMIDICommand(responder, command)) [result addObject:responder];
	}
	
	return result;
}

@end

@implementation NSView (MIKSubviews)

- (NSSet *)mik_allSubviews
{
	NSMutableSet *result = [NSMutableSet setWithArray:[self subviews]];
	for (NSView *subview in [self subviews]) {
		[result unionSet:[subview mik_allSubviews]];
	}
	return result;
}

@end

#endif