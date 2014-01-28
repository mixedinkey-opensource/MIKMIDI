//
//  MIKMIDIErrors.m
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIErrors.h"

static NSString * const MIKMIDIErrorDomain = @"MIKMIDIErrorDomain";

@implementation NSError (MIKMIDI)

+ (instancetype)MIKMIDIErrorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo
{
	return [NSError errorWithDomain:MIKMIDIErrorDomain code:code userInfo:userInfo];
}

@end
