//
//  MIKMIDIMappingManager.m
//  Danceability
//
//  Created by Andrew Madsen on 7/18/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMappingManager.h"
#import "MIKMIDIMapping.h"

@interface MIKMIDIMappingManager ()

@property (nonatomic, strong) NSMutableSet *internalMappings;

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
        [self loadAvailableMappings];
		
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
#if !TARGET_OS_IPHONE
		NSString *appTerminateNotification = NSApplicationWillTerminateNotification;
#else
		NSString *appTerminateNotification = UIApplicationWillTerminateNotification;
#endif
		[nc addObserverForName:appTerminateNotification
						object:nil
						 queue:[NSOperationQueue mainQueue]
					usingBlock:^(NSNotification *note) {
						[self saveMappingsToDisk];
					}];
    }
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Public

- (NSSet *)mappingsForControllerName:(NSString *)name;
{
	if (![name length]) return nil;
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"controllerName LIKE %@", name];
	return [self.mappings filteredSetUsingPredicate:predicate];
}

- (MIKMIDIMapping *)mappingWithName:(NSString *)mappingName;
{
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"name LIKE %@", mappingName];
	return [[self.mappings filteredSetUsingPredicate:predicate] anyObject];
}

- (void)saveMappingsToDisk
{
#if !TARGET_OS_IPHONE
	for (MIKMIDIMapping *mapping in self.mappings) {
		NSURL *fileURL = [self fileURLForMapping:mapping];
		if (!fileURL) {
			NSLog(@"Unable to saving mapping %@ to disk. No file path could be generated", mapping);
			continue;
		}
		
		NSData *mappingXMLData = [[mapping XMLRepresentation] XMLDataWithOptions:NSXMLNodePrettyPrint];
		NSError *error = nil;
		if (![mappingXMLData writeToURL:fileURL options:NSDataWritingAtomic error:&error]) {
			NSLog(@"Error saving MIDI mapping %@: %@", [mapping name], error);
		}
	}
#endif
}

#pragma mark - Private

- (NSURL *)storedMappingsFolder
{
	NSFileManager *fm = [NSFileManager defaultManager];
	
	NSArray *appSupportFolders = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
	if (![appSupportFolders count]) return nil;
	
	NSString *mappingsFolder = [[[appSupportFolders lastObject] stringByAppendingPathComponent:@"Mixedinkey"] stringByAppendingPathComponent:@"MIDI Mappings"];
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

- (void)loadAvailableMappings
{
	NSMutableSet *mappings = [NSMutableSet set];
	
#if !TARGET_OS_IPHONE
	NSURL *mappingsFolder = [self storedMappingsFolder];
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	NSArray *contents = [fm contentsOfDirectoryAtURL:mappingsFolder includingPropertiesForKeys:nil options:0 error:&error];
	if (!contents) {
		NSLog(@"Unable to get contents of directory at %@: %@", mappingsFolder, error);
		return;
	}
	
	for (NSURL *file in contents) {
		if (![[file pathExtension] isEqualToString:@"midimap"]) continue;
		
		// process the mapping file
		MIKMIDIMapping *mapping = [[MIKMIDIMapping alloc] initWithFileAtURL:file];
		if (mapping) [mappings addObject:mapping];
	}
#endif
	
	self.internalMappings = mappings;
}

- (NSURL *)fileURLForMapping:(MIKMIDIMapping *)mapping
{
	NSURL *mappingsFolder = [self storedMappingsFolder];
	NSString *filename = [mapping.name stringByAppendingPathExtension:@"midimap"];
	return [mappingsFolder URLByAppendingPathComponent:filename];
}

#pragma mark - Properties

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key
{
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	
	if ([key isEqualToString:@"mappings"]) {
		keyPaths = [keyPaths setByAddingObject:@"internalMappings"];
	}
	
	return keyPaths;
}

- (NSSet *)mappings { return [self.internalMappings copy]; }

- (void)addMappingsObject:(MIKMIDIMapping *)mapping
{
	MIKMIDIMapping *existing = [self mappingWithName:mapping.name];
	if (existing) [self.internalMappings removeObject:existing];
	[self.internalMappings addObject:mapping];
	
	[self saveMappingsToDisk];
}

- (void)removeMappingsObject:(MIKMIDIMapping *)mapping
{
	[self.internalMappings removeObject:mapping];
	
	// Remove XML file for mapping from disk
	NSURL *mappingURL = [self fileURLForMapping:mapping];
	if (!mappingURL) return;
	NSFileManager *fm = [NSFileManager defaultManager];
	NSError *error = nil;
	if (![fm removeItemAtURL:mappingURL error:&error]) {
		NSLog(@"Error removing mapping file for MIDI mapping %@: %@", mapping, error);
	}
}

@end
