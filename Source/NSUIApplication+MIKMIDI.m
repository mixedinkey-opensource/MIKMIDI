//
//  NSApplication+MIKMIDI.m
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "NSUIApplication+MIKMIDI.h"
#import "MIKMIDIResponder.h"
#import "MIKMIDICommand.h"

@interface MIK_VIEW_CLASS (MIKSubviews)
- (NSSet *)mik_allSubviews; // returns all subviews in flat set
@end

static BOOL MIKObjectRespondsToMIDICommand(id object, MIKMIDICommand *command)
{
	if (!object) return NO;
	return [object conformsToProtocol:@protocol(MIKMIDIResponder)] && [(id<MIKMIDIResponder>)object respondsToMIDICommand:command];
}

@implementation MIK_APPLICATION_CLASS (MIKMIDI)

+ (NSHashTable *)registeredMIKMIDIResponders
{
    static NSHashTable *registeredMIKMIDIResponders = nil;
    static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
#if !TARGET_OS_IPHONE
		NSPointerFunctionsOptions options = NSPointerFunctionsZeroingWeakMemory | NSPointerFunctionsObjectPersonality;
#else
		NSPointerFunctionsOptions options = NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality;
#endif
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

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
{
	NSSet *responders = [self allMIDIResponders];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MIDIIdentifier LIKE %@", identifier];
	return [[responders filteredSetUsingPredicate:predicate] anyObject];
}

#pragma mark - Private

- (NSSet *)respondersForMIDICommand:(MIKMIDICommand *)command
{
	NSSet *allMIDIResponders = [self allMIDIResponders];
	
	NSMutableSet *result = [NSMutableSet set];
	for (id<MIKMIDIResponder> responder in allMIDIResponders) {
		if (MIKObjectRespondsToMIDICommand(responder, command)) [result addObject:responder];
	}
	return result;
}

- (NSSet *)allMIDIResponders
{
	NSMutableSet *result = [NSMutableSet set];
	
	// Go through the entire view hierarchy
	for (MIK_WINDOW_CLASS *window in [self windows]) {
		if ([window conformsToProtocol:@protocol(MIKMIDIResponder)]) {
			[result unionSet:[self recursiveSubrespondersOfMIDIResponder:(id<MIKMIDIResponder>)window]];
		}
#if !TARGET_OS_IPHONE
		if ([[window delegate] conformsToProtocol:@protocol(MIKMIDIResponder)]) {
			[result unionSet:[self recursiveSubrespondersOfMIDIResponder:(id<MIKMIDIResponder>)[window delegate]]];
		}
		if ([[window windowController] conformsToProtocol:@protocol(MIKMIDIResponder)]) {
			[result unionSet:[self recursiveSubrespondersOfMIDIResponder:[window windowController]]];
		}
		NSSet *allSubviews = [[window contentView] mik_allSubviews];
#else
		NSSet *allSubviews = [window.rootViewController.view mik_allSubviews];
#endif
		for (MIK_VIEW_CLASS *subview in allSubviews) {
			if ([subview conformsToProtocol:@protocol(MIKMIDIResponder)]) {
				[result unionSet:[self recursiveSubrespondersOfMIDIResponder:(id<MIKMIDIResponder>)subview]];
			}
		}
	}
	
	for (id<MIKMIDIResponder> responder in [[self class] registeredMIKMIDIResponders]) {
		[result unionSet:[self recursiveSubrespondersOfMIDIResponder:responder]];
	}
	
	return result;
}

- (NSSet *)recursiveSubrespondersOfMIDIResponder:(id<MIKMIDIResponder>)responder
{
	if (![responder respondsToSelector:@selector(subresponders)]) return [NSSet set];
	
	NSMutableSet *result = [NSMutableSet setWithObject:responder];
	
	NSArray *subresponders = [responder subresponders];
	[result addObjectsFromArray:subresponders];
	for (id<MIKMIDIResponder>subresponder in subresponders) {
		[result unionSet:[self recursiveSubrespondersOfMIDIResponder:subresponder]];
	}
	
	return result;
}

@end

@implementation MIK_VIEW_CLASS (MIKSubviews)

- (NSSet *)mik_allSubviews
{
	NSMutableSet *result = [NSMutableSet setWithArray:[self subviews]];
	for (MIK_VIEW_CLASS *subview in [self subviews]) {
		[result unionSet:[subview mik_allSubviews]];
	}
	return result;
}

@end
