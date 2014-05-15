//
//  MIKMIDIMappingXMLParser.h
//  MIDI Soundboard
//
//  Created by Andrew Madsen on 4/15/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDIMapping;

/**
 *  A parser for XML MIDI mapping files. Only used on iOS. On OS X, NSXMLDocument is used
 *  directly instead. Should be considered "private" for use by MIKMIDIMapping.
 */
@interface MIKMIDIMappingXMLParser : NSObject

+ (instancetype)parserWithXMLData:(NSData *)xmlData;
- (instancetype)initWithXMLData:(NSData *)xmlData;

@property (nonatomic, strong, readonly) NSArray *mappings;

@end
