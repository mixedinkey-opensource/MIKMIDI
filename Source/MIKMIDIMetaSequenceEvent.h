//
//  MIKMIDIMetadataSequenceEvent.h
//  MIDI Files Testbed
//
//  Created by Jake Gundersen on 5/22/14.
//  Copyright (c) 2014 Mixed In Key. All rights reserved.
//

#ifdef SWIFTPM
#import "MIKMIDIMetaEvent.h"
#import "MIKMIDIEvent_SubclassMethods.h"
#else
#import <MIKMIDI/MIKMIDIMetaEvent.h>
#import <MIKMIDI/MIKMIDIEvent_SubclassMethods.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/**
 *  A meta event containing sequence information.
 */
@interface MIKMIDIMetaSequenceEvent : MIKMIDIMetaEvent

@end

/**
 *  The mutable counterpart of MIKMIDIMetaSequenceEvent.
 */
@interface MIKMutableMIDIMetaSequenceEvent : MIKMIDIMetaSequenceEvent

@property (nonatomic, readwrite) MusicTimeStamp timeStamp;
@property (nonatomic, readwrite) MIKMIDIMetaEventType metadataType;
@property (nonatomic, strong, readwrite, null_resettable) NSData *metaData;

@end

NS_ASSUME_NONNULL_END
