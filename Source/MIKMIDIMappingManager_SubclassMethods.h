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

@end
