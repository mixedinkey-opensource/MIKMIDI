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

#if !__has_feature(objc_arc)
#error NSApplication+MIKMIDI.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for NSApplication+MIKMIDI.m in the Build Phases for this target
#endif

#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS

@interface MIK_VIEW_CLASS (MIKSubviews)
- (NSSet *)mik_allSubviews; // returns all subviews in flat set
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

#endif

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
		
#if TARGET_OS_IPHONE
		NSPointerFunctionsOptions options = NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality;
#elif (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7)
		NSPointerFunctionsOptions options = NSPointerFunctionsZeroingWeakMemory | NSPointerFunctionsObjectPersonality;
#else
		NSPointerFunctionsOptions options = NSHashTableWeakMemory | NSPointerFunctionsObjectPersonality;
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
	NSSet *registeredResponders = [self respondersForCommand:command inResponders:[self registeredMIDIRespondersIncludingSubresponders]];
	if ([registeredResponders count]) return YES;
	
#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS
	NSSet *viewHierarchyResponders = [self respondersForCommand:command inResponders:[self registeredMIDIRespondersIncludingSubresponders]];
	return ([viewHierarchyResponders count] != 0);
#endif
	return NO;
}

- (void)handleMIDICommand:(MIKMIDICommand *)command;
{
	NSSet *registeredResponders = [self respondersForCommand:command inResponders:[self registeredMIDIRespondersIncludingSubresponders]];
	for (id<MIKMIDIResponder> responder in registeredResponders) {
		[responder handleMIDICommand:command];
	}
	
#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS
	NSMutableSet *viewHierarchyResponders = [[self respondersForCommand:command inResponders:[self MIDIRespondersInViewHierarchy]] mutableCopy];
	[viewHierarchyResponders minusSet:registeredResponders];
	
	for (id<MIKMIDIResponder> responder in viewHierarchyResponders) {
		NSLog(@"WARNING: Found responder %@ for command %@ by traversing view hierarchy. This path for finding MIDI responders is deprecated. Responders should be explicitly registered with NS/UIApplication.", responder, command);
		[responder handleMIDICommand:command];
	}
#endif
}

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
{
	NSSet *registeredResponders = [self registeredMIDIRespondersIncludingSubresponders];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"MIDIIdentifier LIKE %@", identifier];
	NSSet *results = [registeredResponders filteredSetUsingPredicate:predicate];
	id<MIKMIDIResponder> result = [results anyObject];
	
#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS
	if (!result) {
		NSMutableSet *viewHierarchyResponders = [[self MIDIRespondersInViewHierarchy] mutableCopy];
		[viewHierarchyResponders minusSet:registeredResponders];
		results = [viewHierarchyResponders filteredSetUsingPredicate:predicate];
		
		
		if (result) {
			NSLog(@"WARNING: Found responder %@ for identifier %@ by traversing view hierarchy. This path for finding MIDI responders is deprecated. Responders should be explicitly registered with NS/UIApplication.", result, identifier);
		}
	}
#endif
	return result;
}

- (NSSet *)allMIDIResponders
{
	NSMutableSet *result = [[self registeredMIDIRespondersIncludingSubresponders] mutableCopy];
#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS
	[result unionSet:[self MIDIRespondersInViewHierarchy]];
#endif
	return result;
}

- (NSSet *)registeredMIDIRespondersIncludingSubresponders
{
	NSMutableSet *result = [NSMutableSet set];
	for (id<MIKMIDIResponder> responder in [[self class] registeredMIKMIDIResponders]) {
		[result unionSet:[self recursiveSubrespondersOfMIDIResponder:responder]];
	}
	return result;
}

#if MIKMIDI_SEARCH_VIEW_HIERARCHY_FOR_RESPONDERS
- (NSSet *)MIDIRespondersInViewHierarchy
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
	
	return result;
}

#endif

#pragma mark - Private

- (NSSet *)respondersForCommand:(MIKMIDICommand *)command inResponders:(NSSet *)responders
{
	return [responders filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<MIKMIDIResponder>responder, NSDictionary *bindings) {
		return MIKObjectRespondsToMIDICommand(responder, command);
	}]];
}

- (NSSet *)recursiveSubrespondersOfMIDIResponder:(id<MIKMIDIResponder>)responder
{
	NSMutableSet *result = [NSMutableSet setWithObject:responder];
	if (![responder respondsToSelector:@selector(subresponders)]) return result;
	
	NSArray *subresponders = [responder subresponders];
	[result addObjectsFromArray:subresponders];
	for (id<MIKMIDIResponder>subresponder in subresponders) {
		[result unionSet:[self recursiveSubrespondersOfMIDIResponder:subresponder]];
	}
	
	return result;
}

@end
