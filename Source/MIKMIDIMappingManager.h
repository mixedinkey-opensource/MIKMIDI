//
//  MIKMIDIMappingManager.h
//  Danceability
//
//  Created by Andrew Madsen on 7/18/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

#define kMIKMIDIMappingFileExtension @"midimap"

@class MIKMIDIMapping;

/**
 *  MIKMIDIMappingManager provides a centralized way to manage an application's
 *  MIDI mappings. It handles both bundled (built in) mapping files, as well
 *  as user-customized mappings. It will automatically load both bundled and
 *  user mappings from disk. It will also save user mappings to an appropriate
 *  location on disk, providing an easy to way to support the ability to import user
 *  mappings to an applicaation.
 *
 *  MIKMIDIMappingManager is a singleton.
 */
@interface MIKMIDIMappingManager : NSObject

/**
 *  Used to obtain the shared MIKMIDIMappingManager instance.
 *  MIKMIDIMappingManager should not be created directly using +alloc/-init or +new.
 *  Rather, the singleton shared instance should always be obtained by calling this method.
 *
 *  @return The shared MIKMIDIMappingManager instance.
 */
+ (instancetype)sharedManager;

/**
 *  Used to obtain the set of all mappings, both user-supplied and bundled, for the controller
 *  specified by name. Typically, name is the string obtained by calling -[MIKMIDIDevice name].
 *
 *  @param name The name of the controller for which available mappings are desired.
 *
 *  @return An NSSet containing MIKMIDIMapping instances.
 */
- (NSSet *)mappingsForControllerName:(NSString *)name;

/**
 *  Used to obtain the set of bundled mappings for the controller
 *  specified by name. Typically, name is the string obtained by calling -[MIKMIDIDevice name].
 *
 *  @param name The name of the controller for which available bundled mappings are desired.
 *
 *  @return An NSSet containing MIKMIDIMapping instances.
 */
- (NSSet *)bundledMappingsForControllerName:(NSString *)name;

/**
 *  Used to obtain the set of user-supplied mappings for the controller
 *  specified by name. Typically, name is the string obtained by calling -[MIKMIDIDevice name].
 *
 *  @param name The name of the controller for which available user-supplied mappings are desired.
 *
 *  @return An NSSet containing MIKMIDIMapping instances.
 */
- (NSSet *)userMappingsForControllerName:(NSString *)name;

/**
 *  Used to obtaining a mapping file with a given mapping name.
 *
 *  @param mappingName NSString representing the mapping name for the desired mapping.
 *
 *  @return An MIKMIDIMapping instance, or nil if no mapping could be found.
 */
- (MIKMIDIMapping *)mappingWithName:(NSString *)mappingName;

#if !TARGET_OS_IPHONE
/**
 *  Import and load a user-supplied MIDI mapping XML file. This method loads the MIDI mapping
 *  file specified by URL and adds it to the set returned by -userMappings. The newly imported mapping
 *  file is also copied into the application's user mapping folder so it will be loaded again automatically
 *  on subsequent launches.
 *
 *  If shouldOverwrite is YES, and an existing file with the same URL as would be used
 *  to save the imported mapping already exists, the existing file is deleted. Otherwise,
 *  a unique name is used for the newly imported mapping, preserving both mapping files.
 * 
 *  @note This method is currently only available on OS X. See https://github.com/mixedinkey-opensource/MIKMIDI/issues/2
 *
 *  @param URL             The fileURL for the mapping file to be imported. Should not be nil.
 *  @param shouldOverwrite YES if an existing mapping with the same file name should be overwitten, NO to use a unique file name for the newly imported mapping.
 *  @param error           Pointer to an NSError used to return information about an error, if any.
 *
 *  @return An MIKMIDIMapping instance for the imported file, or nil if there was an error.
 */
- (MIKMIDIMapping *)importMappingFromFileAtURL:(NSURL *)URL overwritingExistingMapping:(BOOL)shouldOverwrite error:(NSError **)error;

/**
 *  Saves user mappings to disk. These mappings are currently saved to a folder at <AppSupport>/<ApplicationBundleID>/MIDI Mappings.
 *  This folder is created automatically if necessary.
 * 
 *  This method can be called manually to initiate a save, but is also called automatically anytime a new user mapping is added (via
 *  -importMappingFromFileAtURL:overwritingExistingMapping:error: or -addUserMappingsObject:) as well as upon application termination.
 *
 *  @note This method is currently only available on OS X. See https://github.com/mixedinkey-opensource/MIKMIDI/issues/2 
 */
- (void)saveMappingsToDisk;
#endif

// Properties

/**
 *  MIDI mappings loaded from the application's bundle. These are built in mapping, shipped
 *  with the application.
 */
@property (nonatomic, strong, readonly) NSSet *bundledMappings;

/**
 *  MIDI mappings loaded from the user mappings folder on disk, as well as added at runtime.
 */
@property (nonatomic, strong, readonly) NSSet *userMappings;

/**
 *  Add a new user mapping. The mapping will automatically be saved to a file in the
 *  user mappings folder on disk, to be loaded automatically the next time the application is run.
 *
 *  @param mapping An MIKMIDIMapping instance.
 */
- (void)addUserMappingsObject:(MIKMIDIMapping *)mapping;

/**
 *  Remove an existing user mapping. If the mapping is already saved in a file in
 *  the user mappings folder on disk, the mapping's file will be deleted.
 *
 *  @param mapping An MIKMIDIMapping instance.
 */
- (void)removeUserMappingsObject:(MIKMIDIMapping *)mapping; // Deletes mapping from disk

/**
 *  All mappings, including both user and bundled mappings.
 *
 *  The value of this property is the same as the union of -bundledMappings and -userMappings
 *
 */
@property (nonatomic, strong, readonly) NSSet *mappings;

@end
