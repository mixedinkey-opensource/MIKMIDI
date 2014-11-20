//
//  MIKMIDIMetaCuePointEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIMetaTextEvent.h"

/**
 *  A meta event containing cue point information.
 */
@interface MIKMIDIMetaCuePointEvent : MIKMIDIMetaTextEvent

@end

/**
 *  The mutable counterpart of MIKMIDIMetaCuePointEvent.
 */
@interface MIKMutableMIDIMetaCuePointEvent : MIKMIDIMetaCuePointEvent

@end