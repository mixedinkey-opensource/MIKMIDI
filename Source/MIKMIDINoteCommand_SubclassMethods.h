//
//  MIKMIDIChannelVoiceCommand_SubclassMethods.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 10/10/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#ifdef SWIFTPM
#import "MIKMIDINoteCommand.h"
#else
#import <MIKMIDI/MIKMIDINoteCommand.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface MIKMIDINoteCommand ()

@property (nonatomic, readwrite, getter=isNoteOn) BOOL noteOn;

@end

NS_ASSUME_NONNULL_END
