//
//  MIKMIDISystemExclusiveCommand.h
//  MIDI Testbed
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDISystemMessageCommand.h"

@interface MIKMIDISystemExclusiveCommand : MIKMIDISystemMessageCommand

@property (nonatomic, readonly) UInt32 manufacturerID;
@property (nonatomic, strong, readonly) NSData *sysexData;

@end

@interface MIKMutableMIDISystemExclusiveCommand : MIKMIDISystemExclusiveCommand

@property (nonatomic, readwrite) UInt32 manufacturerID;
@property (nonatomic, strong, readwrite) NSData *sysexData;

@end