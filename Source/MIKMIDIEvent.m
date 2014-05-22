//
//  MIKMIDIEvent.m
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/21/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#import "MIKMIDIEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#import "MIKMIDIUtilities.h"
#import "MIKMIDIUtilities.h"

static NSMutableSet *registeredMIKMIDIEventSubclasses;

@implementation MIKMIDIEvent

+ (void)registerSubclass:(Class)subclass;
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		registeredMIKMIDIEventSubclasses = [[NSMutableSet alloc] init];
	});
	[registeredMIKMIDIEventSubclasses addObject:subclass];
}

+ (BOOL)isMutable { return NO; }

+ (BOOL)supportsMusicEventType:(MusicEventType)type { return NO; }
+ (Class)immutableCounterpartClass; { return [MIKMIDIEvent class]; }
+ (Class)mutableCounterpartClass; { return [MIKMutableMIDIEvent class]; }

+ (instancetype)midiEventWithTimestamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data
{
    Class subclass = [[self class] subclassForEventType:eventType];
	if (!subclass) subclass = self;
	if ([self isMutable]) subclass = [subclass mutableCounterpartClass];
	MIKMIDIEvent *result = [[subclass alloc] initWithTimeStamp:timeStamp eventType:eventType data:data];
    return result;
}

- (id)init
{
    self = [self initWithTimeStamp:0 eventType:kMusicEventType_NULL data:nil];
    if (self) {
        self.internalData = [NSMutableData data];
    }
    return self;
}

- (id)initWithTimeStamp:(MusicTimeStamp)timeStamp eventType:(MusicEventType)eventType data:(NSData *)data
{
	self = [super init];
	if (self) {
		_musicTimeStamp = timeStamp;
		_eventType = eventType;
        self.internalData = [data mutableCopy];
	}
	return self;
}

- (NSString *)additionalEventDescription
{
    return @"";
}

- (NSString *)description
{
    NSString *additionalDescription = [self additionalEventDescription];
    if ([additionalDescription length] > 0) {
        additionalDescription = [NSString stringWithFormat:@"%@ ", additionalDescription];
    }
    return [NSString stringWithFormat:@"%@ Timestamp: %f Type: %u, %@", [super description], self.musicTimeStamp, (unsigned int)self.eventType, additionalDescription];
}

#pragma mark - Private

+ (Class)subclassForEventType:(MusicEventType)eventType
{
	Class result = nil;
	for (Class subclass in registeredMIKMIDIEventSubclasses) {
		if ([subclass supportsMusicEventType:eventType]) {
			result = subclass;
			break;
		}
    }
	return result;
}

#pragma mark - NSCopying

- (id)copyWithZone:(NSZone *)zone
{
	Class copyClass = [[self class] immutableCounterpartClass];
	MIKMIDIEvent *result = [[copyClass alloc] init];
	result.internalData = self.internalData;
	result.eventType = self.eventType;
	result.musicTimeStamp = self.musicTimeStamp;
	return result;
}

- (id)mutableCopy
{
	Class copyClass = [[self class] mutableCounterpartClass];
	MIKMutableMIDIEvent *result = [[copyClass alloc] init];
	result.internalData = self.internalData;
	result.eventType = self.eventType;
	result.musicTimeStamp = self.musicTimeStamp;
	return result;
}

- (NSData *)data { return [self.internalData copy]; }

- (void)setData:(NSData *)data
{
	if (![[self class] isMutable]) return MIKMIDI_RAISE_MUTATION_ATTEMPT_EXCEPTION;
	
	self.internalData = [data mutableCopy];
}

@end

@implementation MIKMutableMIDIEvent

+ (BOOL)isMutable { return YES; }

+ (BOOL)supportsMusicEventType:(MusicEventType)type { return [[self immutableCounterpartClass] supportsMusicEventType:type]; }

@dynamic eventType;
@dynamic channel;
@dynamic data;

@end