//
//  MIKMIDICommandScheduler.h
//  MIKMIDI
//
//  Created by Chris Flesner on 7/3/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 *	Objects that conform to this protocol can be used as a destination for MIDI commands to
 *	be sent to by MIKMIDISequencer.
 *
 *	@see MIKMIDISequencer
 */
@protocol MIKMIDICommandScheduler <NSObject>

- (void)scheduleMIDICommands:(NSArray *)commands;

@end
