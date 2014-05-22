//
//  MIKMIDIEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface MIKMIDIEvent : NSObject <NSCopying>

@property (nonatomic, readonly) MusicEventType eventType;
@property (nonatomic, readonly) NSUInteger channel;
@property (nonatomic, readonly) MusicTimeStamp musicTimeStamp;
@property (nonatomic, readonly) NSData *data;

+ (instancetype)midiEventWithTimestamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data;


@end

@interface MIKMutableMIDIEvent : MIKMIDIEvent

@property (nonatomic, readwrite) MusicEventType eventType;
@property (nonatomic, readwrite) NSUInteger channel;
@property (nonatomic, strong, readwrite) NSMutableData *data;

@end