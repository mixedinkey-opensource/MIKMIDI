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

@interface MIKMIDIMappingManager : NSObject

+ (instancetype)sharedManager;

- (NSSet *)mappingsForControllerName:(NSString *)name;
- (MIKMIDIMapping *)mappingWithName:(NSString *)mappingName;

#if !TARGET_OS_IPHONE
- (MIKMIDIMapping *)importMappingFromFileAtURL:(NSURL *)URL error:(NSError **)error;
- (void)saveMappingsToDisk;
#endif

// Properties

@property (nonatomic, strong, readonly) NSSet *mappings;
- (void)addMappingsObject:(MIKMIDIMapping *)mapping;
- (void)removeMappingsObject:(MIKMIDIMapping *)mapping; // Deletes mapping from disk

@end
