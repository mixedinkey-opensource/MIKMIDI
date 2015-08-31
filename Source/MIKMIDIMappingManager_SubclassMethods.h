//
//  MIKMIDIMappingManager_SubclassMethods.h
//  MIKMIDI
//
//  Created by Chris Flesner on 8/11/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//


#import "MIKMIDIMappingManager.h"

@class MIKMIDIMapping;


@interface MIKMIDIMappingManager ()

/**
 *  Used to determine the file name for a user mapping. This file name does *not* include the
 *	file extension, which will be added by the caller.
 *
 *  @param mapping The mapping a file name is needed for.
 *
 *  @return A file name for the mapping.
 */
- (NSString *)fileNameForMapping:(MIKMIDIMapping *)mapping;

/**
 *	When deleting user mappings, this method is called as a way to provide any additional
 *	file names that the mapping may have had in past versions of -fileNameForMapping:
 *
 *	If you have changed the naming scheme that -fileNameForMapping: uses in any user-reaching
 *	code, you will probably want to implement this method as well, so users will be able to
 *	properly delete mappings with the old naming scheme.
 *
 *	Just as with -fileNameForMapping:, the file names should *not* include the file extension.
 *
 *	@param mapping The mapping to return legacy file names for.
 *
 *	@return An array of legacy file names, or nil.
 */
- (NSArray *)legacyFileNamesForUserMappingsObject:(MIKMIDIMapping *)mapping;

@end
