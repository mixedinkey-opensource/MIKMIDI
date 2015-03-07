//
//  MIKMIDIErrors.m
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIErrors.h"

#if !__has_feature(objc_arc)
#error MIKMIDIErrors.m must be compiled with ARC. Either turn on ARC for the project or set the -fobjc-arc flag for MIKMIDIErrors.m in the Build Phases for this target
#endif

NSString * const MIKMIDIErrorDomain = @"MIKMIDIErrorDomain";

@implementation NSError (MIKMIDI)

+ (instancetype)MIKMIDIErrorWithCode:(MIKMIDIErrorCode)code userInfo:(NSDictionary *)userInfo;
{
	return [NSError errorWithDomain:MIKMIDIErrorDomain code:code userInfo:userInfo];
}

@end
