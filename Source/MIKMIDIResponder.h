//
//  MIKMIDIResponder.h
//  Energetic
//
//  Created by Andrew Madsen on 3/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MIKMIDICommand;

@protocol MIKMIDIResponder <NSObject>

@required
- (NSString *)MIDIIdentifier;
- (BOOL)respondsToMIDICommand:(MIKMIDICommand *)command;
- (void)handleMIDICommand:(MIKMIDICommand *)command;

@end
