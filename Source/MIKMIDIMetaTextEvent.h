//
//  MIKMIDIMetadataTextEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"

@interface MIKMIDIMetaTextEvent : MIKMIDIMetaEvent

@property (nonatomic, readonly) NSString *string;

@end

@interface MIKMutableMIDIMetaTextEvent : MIKMIDIMetaTextEvent

@property (nonatomic, readwrite) NSString *string;

@end