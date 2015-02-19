//
//  MIKMIDIMappingManager.m
//  Danceability
//
//  Created by Andrew Madsen on 7/18/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

#import "MIKMIDIMappingManager.h"
#import "MIKMIDIMapping.h"
#import "MIKMIDIErrors.h"

#if !__has_feature(objc_arc)
#error MIKMIDIMappingManager.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIMappingManager.m in the Build Phases for this target
#endif

@interface MIKMIDIMapping (SemiPrivate)

@property (nonatomic, readwrite, getter = isBundledMapping) BOOL bundledMapping;

@end

@interface MIKMIDIMappingManager ()

@property (nonatomic, strong, readwrite) NSSet *bundledMappings;
@property (nonatomic, strong) NSMutableSet *internalUserMappings;

@property (nonatomic, strong) NSMutableArray *blockBasedObservers;

@end

static MIKMIDIMappingManager *sharedManager = nil;

@implementation MIKMIDIMappingManager

+ (instancetype)sharedManager;
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		sharedManager = [[self alloc] init];
	});
	return sharedManager;
}

- (id)init
{
    self = [super init];
    if (self) {
		[self loadBundledMappings];
        [self loadAvailableUserMappings];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
#if !TARGET_OS_IPHONE
		NSString *appTerminateNotification = NSApplicationWillTerminateNotification;
#else
		NSString *appTerminateNotification = UIApplicationWillTerminateNotification;
#endif
		self.blockBasedObservers = [NSMutableArray array];
		id observer = [nc addObserverForName:appTerminateNotification
									  object:nil
									   queue:[NSOperationQueue mainQueue]
								  usingBlock:^(NSNotification *note) {
									  [self saveMappingsToDisk];
								  }];
		[self.blockBasedObservers addObject:observer];
    }
    return self;
}

- (void)dealloc
{
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];
	for (id observer in self.blockBasedObservers) { [nc removeObserver:observer]; }
	self.blockBasedObservers = nil;
}

#pragma mark - Public

- (NSSet *)mappingsForControllerName:(NSString *)name;
{
	if (![name length]) return nil;
	NSSet *bundledMappings = [self bundledMappingsForControllerName:name];
	NSSet *userMappings = [self userMappingsForControllerName:name];
	return [bundledMappings setByAddingObjectsFromSet:userMappings];
}

- (NSSet *)bundledMappingsForControllerName:(NSString *)name
{
	if (![name length]) return [NSSet set];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"controllerName LIKE %@", name];
	return [self.bundledMappings filteredSetUsingPredicate:predicate];
}

- (NSSet *)userMappingsForControllerName:(NSString *)name
{
	if (![name length]) return [NSSet set];
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"controllerName LIKE %@", name];
	return [self.userMappings filteredSetUsingPredicate:predicate];
}

- (MIKMIDIMapping *)mappingWithName:(NSString *)mappingName;
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", mappingName];
	return [[self.mappings filteredSetUsingPredicate:predicate] anyObject];
}

- (MIKMIDIMapping *)importMappingFromFileAtURL:(NSURL *)URL overwritingExistingMapping:(BOOL)shouldOverwrite error:(NSError **)error;
{
#if !TARGET_OS_IPHONE
	error = error ? error : &(NSError *__autoreleasing){ nil };
	if (![[URL pathExtension] isEqualToString:kMIKMIDIMappingFileExtension]) {
		NSString *recoverySuggestion = [NSString stringWithFormat:NSLocalizedString(@"%1$@ can't be imported, because it does not have the file extension %2$@.", @"MIDI mapping import failed because of incorrect file extension message. Placeholder 1 is the filename, 2 is the required extension (e.g. 'midimap')")];
		NSDictionary *userInfo = @{NSLocalizedFailureReasonErrorKey : NSLocalizedString(@"Incorrect File Extension", @"Incorrect File Extension"),
								   NSLocalizedRecoverySuggestionErrorKey : recoverySuggestion};
		*error = [NSError MIKMIDIErrorWithCode:MIKMIDIMappingIncorrectFileExtensionErrorCode userInfo:userInfo];
		return nil;
	}
	
	MIKMIDIMapping *mapping = [[MIKMIDIMapping alloc] initWithFileAtURL:URL error:error];;
	if (!mapping) return nil;
	if ([self.userMappings containsObject:mapping]) return mapping; // Already have it, so don't copy the file.
	
	NSFileManager *fm = [NSFileManager defaultManager];
	// FIXME: This should write the newly imported mapping file immediately.
	NSURL *destinationURL = [self fileURLForMapping:mapping shouldBeUnique:!shouldOverwrite];
	if (shouldOverwrite && [fm fileExistsAtPath:[destinationURL path]]) {
		if (![fm removeItemAtURL:destinationURL error:error]) return nil;
	}
	
	[self addUserMappingsObject:mapping];
	return mapping;
#endif // TARGET_OS_IPHONE
	return nil;
}

- (void)saveMappingsToDisk
{
#if !TARGET_OS_IPHONE
	for (MIKMIDIMapping *mapping in self.userMappings) {
		NSURL *fileURL = [self fileURLForMapping:mapping shouldBeUnique:NO];
		if (!fileURL) {
			NSLog(@"Unable to saving mapping %@ to disk. No file path could be generated", mapping);
			continue;
		}
		
		[mapping writeToFileAtURL:fileURL error:NULL];
	}
#endif
}

#pragma mark - Private

- (NSURL *)userMappingsFolder
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSArray *appSupportFolders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	if (![appSupportFolders count]) return nil;
	
	NSString *bundleID = [[NSBundle mainBundle] bundleIdentifier];
	if (![bundleID length]) bundleID = @"com.mixedinkey.MIKMIDI"; // Shouldn't happen, except perhaps in command line app.
	NSString *mappingsFolder = [[[appSupportFolders lastObject] stringByAppendingPathComponent:bundleID] stringByAppendingPathComponent:@"MIDI Mappings"];
	BOOL isDirectory;
	BOOL folderExists = [fm fileExistsAtPath:mappingsFolder isDirectory:&isDirectory];
	if (!folderExists) {
		NSError *error = nil;
		if (![fm createDirectoryAtPath:mappingsFolder withIntermediateDirectories:YES attributes:nil error:&error]) {
			NSLog(@"Unable to create MIDI mappings folder: %@", error);
			return nil;
		}
	}
	return [NSURL fileURLWithPath:mappingsFolder isDirectory:YES];
}

- (void)loadAvailableUserMappings
{
	NSMutableSet *mappings = [NSMutableSet set];
	
	NSURL *mappingsFolder = [self userMappingsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *userMappingFileURLs = [fm contentsOfDirectoryAtURL:mappingsFolder includingPropertiesForKeys:nil options:0 error:&error];
	if (userMappingFileURLs) {
		for (NSURL *file in userMappingFileURLs) {
			if (![[file pathExtension] isEqualToString:kMIKMIDIMappingFileExtension]) continue;
			
			// process the mapping file
			MIKMIDIMapping *mapping = [[MIKMIDIMapping alloc] initWithFileAtURL:file];
			if (mapping) [mappings addObject:mapping];
		}
	} else {
		NSLog(@"Unable to get contents of directory at %@: %@", mappingsFolder, error);
	}
	
	self.internalUserMappings = mappings;
}

- (void)loadBundledMappings
{
	NSMutableSet *mappings = [NSMutableSet set];
	
	NSBundle *bundle = [NSBundle mainBundle];
	NSArray *bundledMappingFileURLs = [bundle URLsForResourcesWithExtension:kMIKMIDIMappingFileExtension subdirectory:nil];
	for (NSURL *file in bundledMappingFileURLs) {
		MIKMIDIMapping *mapping = [[MIKMIDIMapping alloc] initWithFileAtURL:file];
		mapping.bundledMapping = YES;
		if (mapping) [mappings addObject:mapping];
	}
	
	self.bundledMappings = mappings;
}

- (NSURL *)fileURLForMapping:(MIKMIDIMapping *)mapping shouldBeUnique:(BOOL)unique
{
	NSURL *mappingsFolder = [self userMappingsFolder];
	NSString *filename = [mapping.name stringByAppendingPathExtension:kMIKMIDIMappingFileExtension];
	
	NSURL *result = [mappingsFolder URLByAppendingPathComponent:filename];
	
	if (unique) {
		NSFileManager *fm = [NSFileManager defaultManager];
		unsigned long numberSuffix = 0;
		while ([fm fileExistsAtPath:[result path]]) {
			if (numberSuffix > 1000) return nil; // Don't go crazy
			NSString *name = [mapping.name stringByAppendingFormat:@" %lu", ++numberSuffix];
			filename = [name stringByAppendingPathExtension:kMIKMIDIMappingFileExtension];
			result = [mappingsFolder URLByAppendingPathComponent:filename];
		}
	}
	
	return result;
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"userMappings"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalUserMappings"];
	}
	
	if ([key isEqualToString:@"mappings"]) {
		keyPaths = [keyPaths setByAddingObjectsFromArray:@[@"userMappings", @"bundledMappings"]];
	}
	
	return keyPaths;
}

- (NSSet *)userMappings { return [self.internalUserMappings copy]; }

- (NSSet *)mappings { return [self.bundledMappings setByAddingObjectsFromSet:self.userMappings]; }

- (void)addUserMappingsObject:(MIKMIDIMapping *)mapping
{
	MIKMIDIMapping *existing = [self mappingWithName:mapping.name];
	if (existing) [self.internalUserMappings removeObject:existing];
	mapping.bundledMapping = NO;
	[self.internalUserMappings addObject:mapping];
	
	[self saveMappingsToDisk];
}

- (void)removeUserMappingsObject:(MIKMIDIMapping *)mapping
{
	[self.internalUserMappings removeObject:mapping];
	
	if ([self.bundledMappings containsObject:mapping]) return;
	
	// Remove XML file for mapping from disk
	NSURL *mappingURL = [self fileURLForMapping:mapping shouldBeUnique:NO];
	if (!mappingURL) return;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	if (![fm removeItemAtURL:mappingURL error:&error]) {
		NSLog(@"Error removing mapping file for MIDI mapping %@: %@", mapping, error);
	}
}

@end
