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
#import <objc/runtime.h>

#if !__has_feature(objc_arc)
#error NSApplication+MIKMIDI.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for NSApplication+MIKMIDI.m in the Build Phases for this target
#endif

static BOOL MIKObjectRespondsToMIDICommand(id object, MIKMIDICommand *command)
{
	if (!object) return NO;
	return [object conformsToProtocol:@protocol(MIKMIDIResponder)] && [(id<MIKMIDIResponder>)object respondsToMIDICommand:command];
}

@interface MIKMIDIResponderHierarchyManager : NSObject

// Public
- (void)refreshRespondersAndSubresponders;
- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;

// Properties
@property (nonatomic, strong) NSHashTable *registeredMIKMIDIResponders;
@property (nonatomic, strong, readonly) NSSet *registeredMIKMIDIRespondersAndSubresponders;

@property (nonatomic, strong) NSHashTable *subrespondersCache;

@property (nonatomic) BOOL shouldCacheMIKMIDISubresponders;

@property (nonatomic, strong, readonly) NSSet *allMIDIResponders;

@property (nonatomic, strong, readonly) NSPredicate *midiIdentifierPredicate;

@end

@implementation MIKMIDIResponderHierarchyManager

+ (NSPointerFunctionsOptions)hashTableOptions
{
#if TARGET_OS_IPHONE
	return NSPointerFunctionsWeakMemory | NSPointerFunctionsObjectPersonality;
#elif (MAC_OS_X_VERSION_MIN_REQUIRED <= MAC_OS_X_VERSION_10_7)
	return NSPointerFunctionsZeroingWeakMemory | NSPointerFunctionsObjectPersonality;
#else
	return NSHashTableWeakMemory | NSPointerFunctionsObjectPersonality;
#endif
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		NSPointerFunctionsOptions options = [[self class] hashTableOptions];
		_registeredMIKMIDIResponders = [[NSHashTable alloc] initWithOptions:options capacity:0];

		_shouldCacheMIKMIDISubresponders = NO;
	}
	return self;
}

- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder;
{
	[self.registeredMIKMIDIResponders addObject:responder];
	[self refreshRespondersAndSubresponders];
}

- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder;
{
	[self.registeredMIKMIDIResponders removeObject:responder];
	[self refreshRespondersAndSubresponders];
}

#pragma mark - Public

- (void)refreshRespondersAndSubresponders
{
	self.subrespondersCache = nil;
}

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier
{
	NSSet *registeredResponders = self.registeredMIKMIDIRespondersAndSubresponders;
	
	id<MIKMIDIResponder> result = nil;
	for (id<MIKMIDIResponder> responder in registeredResponders) {
		if ([[responder MIDIIdentifier] isEqualToString:identifier]) {
			result = responder;
			break;
		}
	}

	return result;
}

#pragma mark - Private

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

#pragma mark - Properties

- (NSSet *)registeredMIKMIDIRespondersAndSubresponders
{
	if (self.shouldCacheMIKMIDISubresponders && self.subrespondersCache != nil) {
		return [self.subrespondersCache setRepresentation];
	}
	
	NSMutableSet *result = [NSMutableSet set];
	for (id<MIKMIDIResponder> responder in self.registeredMIKMIDIResponders) {
		[result unionSet:[self recursiveSubrespondersOfMIDIResponder:responder]];
	}

	if (self.shouldCacheMIKMIDISubresponders) {
		// Load cache with result
		NSPointerFunctionsOptions options = [[self class] hashTableOptions];
		self.subrespondersCache = [[NSHashTable alloc] initWithOptions:options capacity:0];
		for (id object in result) { [self.subrespondersCache addObject:object]; }
	}
	
	return [result copy];
}

+ (NSSet *)keyPathsForValuesAffectingAllMIDIResponders
{
	return [NSSet setWithObjects:@"registeredMIKMIDIRespondersAndSubresponders", nil];
}

- (NSSet *)allMIDIResponders
{
	return self.registeredMIKMIDIRespondersAndSubresponders;
}

@synthesize midiIdentifierPredicate = _midiIdentifierPredicate;
- (NSPredicate *)midiIdentifierPredicate
{
	if (!_midiIdentifierPredicate) {
		_midiIdentifierPredicate = [NSPredicate predicateWithFormat:@"MIDIIdentifier LIKE $MIDIIdentifier"];
	}
	return _midiIdentifierPredicate;
}

@end

#pragma mark -

@implementation MIK_APPLICATION_CLASS (MIKMIDI)

- (void)registerMIDIResponder:(id<MIKMIDIResponder>)responder; { [self.mikmidi_responderHierarchyManager registerMIDIResponder:responder]; }

- (void)unregisterMIDIResponder:(id<MIKMIDIResponder>)responder; { [self.mikmidi_responderHierarchyManager unregisterMIDIResponder:responder]; }

- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
{
	MIKMIDIResponderHierarchyManager *manager = self.mikmidi_responderHierarchyManager;
	
	NSSet *registeredResponders = [self respondersForCommand:command inResponders:manager.allMIDIResponders];
	if ([registeredResponders count]) return YES;

	return NO;
}

- (void)handleMIDICommand:(MIKMIDICommand *)command;
{
	MIKMIDIResponderHierarchyManager *manager = self.mikmidi_responderHierarchyManager;
	NSSet *registeredResponders = [self respondersForCommand:command inResponders:manager.allMIDIResponders];
	for (id<MIKMIDIResponder> responder in registeredResponders) {
		[responder handleMIDICommand:command];
	}
}

- (id<MIKMIDIResponder>)MIDIResponderWithIdentifier:(NSString *)identifier;
{
	return [self.mikmidi_responderHierarchyManager MIDIResponderWithIdentifier:identifier];
}

- (NSSet *)allMIDIResponders { return [self.mikmidi_responderHierarchyManager allMIDIResponders]; }
- (void)refreshMIDIRespondersAndSubresponders { [self.mikmidi_responderHierarchyManager refreshRespondersAndSubresponders]; }

#pragma mark - Private

- (NSSet *)respondersForCommand:(MIKMIDICommand *)command inResponders:(NSSet *)responders
{
	return [responders filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id<MIKMIDIResponder>responder, NSDictionary *bindings) {
		return MIKObjectRespondsToMIDICommand(responder, command);
	}]];
}

#pragma mark - Properties

- (MIKMIDIResponderHierarchyManager *)mikmidi_responderHierarchyManager
{
	static MIKMIDIResponderHierarchyManager *manager = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		manager = [[MIKMIDIResponderHierarchyManager alloc] init];
	});
	return manager;
}

+ (NSSet *)keyPathsForValuesAffectingShouldCacheMIKMIDISubresponders
{
	return [NSSet setWithObject:@"mikmidi_responderHierarchyManager.shouldCacheMIKMIDISubresponders"];
}
- (BOOL)shouldCacheMIKMIDISubresponders { return [self.mikmidi_responderHierarchyManager shouldCacheMIKMIDISubresponders]; }
- (void)setShouldCacheMIKMIDISubresponders:(BOOL)flag { [self.mikmidi_responderHierarchyManager setShouldCacheMIKMIDISubresponders:flag]; }

@end
