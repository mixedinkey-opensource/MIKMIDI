//
//  MIKMIDIEventMIDINoteMessage.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"

@interface MIKMIDINoteEvent : MIKMIDIEvent

@property (nonatomic, readonly) UInt8		note;
@property (nonatomic, readonly) UInt8		velocity;
@property (nonatomic, readonly) UInt8		releaseVelocity;
@property (nonatomic, readonly) Float32		duration;

@end

@interface MIKMutableMIDINoteEvent : MIKMIDIEvent

@end