//
//  MIKMIDISynthesizerInstrument.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/19/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDISynthesizerInstrument.h"

@implementation MIKMIDISynthesizerInstrument

+ (instancetype)instrumentWithID:(MusicDeviceInstrumentID)instrumentID name:(NSString *)name
{	
	return [[self alloc] initWithName:name instrumentID:instrumentID];
}

- (instancetype)initWithName:(NSString *)name instrumentID:(MusicDeviceInstrumentID)instrumentID
{
	self = [super init];
	if (self) {
		_name = name ?: @"No instrument name";
		_instrumentID = instrumentID;
	}
	return self;
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"%@ %@ (%@)", [super description], self.name, @(self.instrumentID)];
}

- (BOOL)isEqual:(id)object
{
	if (object == self) return YES;
	if (![object isMemberOfClass:[self class]]) return NO;
	if (self.instrumentID != [object instrumentID]) return NO;
	return [self.name isEqualToString:[object name]];
}

- (NSUInteger)hash
{
	return (NSUInteger)self.instrumentID;
}

@end
