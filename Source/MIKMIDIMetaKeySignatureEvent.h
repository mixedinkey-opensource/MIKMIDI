//
//  MIKMIDIMetaKeySignatureEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/23/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaEvent.h"

@interface MIKMIDIMetaKeySignatureEvent : MIKMIDIMetaEvent

@property (nonatomic, readonly) UInt8 key;
@property (nonatomic, readonly) UInt8 scale;

@end

@interface MIKMutableMIDIMetaKeySignatureEvent : MIKMIDIMetaKeySignatureEvent

@property (nonatomic, readwrite) UInt8 key;
@property (nonatomic, readwrite) UInt8 scale;

@end