//
//  MIKMIDIEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MIKMIDIEvent : NSObject

@property (nonatomic, assign) MusicEventType eventType;
@property (nonatomic, assign) NSUInteger channel;
@property (nonatomic, assign) NSUInteger parameter;
@property (nonatomic, assign) NSUInteger parameterTwo;

@end
