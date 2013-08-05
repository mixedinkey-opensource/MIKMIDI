//
//  MIKMIDIErrors.h
//  Danceability
//
//  Created by Andrew Madsen on 7/19/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString * const MIKMIDIErrorDomain;

typedef NS_ENUM(NSInteger, MIKMIDIErrorCode) {
	MIKMIDIUnknownErrorCode = 1,
	MIKMIDIDeviceConnectionLostErrorCode,
	
	MIKMIDIMappingFailedErrorCode,
};

@interface NSError (MIKMIDI)

+ (instancetype)MIKMIDIErrorWithCode:(NSInteger)code userInfo:(NSDictionary *)userInfo;

@end