//
//  MIKMMCLocateTargetCommand.h
//  MIKMIDI
//
//  Created by Andrew R Madsen on 2/6/22.
//  Copyright © 2022 Mixed In Key. All rights reserved.
//

#import <MIKMIDI/MIKMIDIMachineControlCommand.h>

typedef NS_ENUM(UInt8, MIKMMCLocateTargetCommandTimeType) {
    MIKMMCLocateTargetCommandTimeType24FPS = 0x00,
    MIKMMCLocateTargetCommandTimeType25FPS = 0x01,
    MIKMMCLocateTargetCommandTimeType30FPSDropFrame = 0x02,
    MIKMMCLocateTargetCommandTimeType30FPS = 0x03,
};

NS_ASSUME_NONNULL_BEGIN

@interface MIKMMCLocateTargetCommand : MIKMIDIMachineControlCommand

+ (instancetype)locateTargetCommandWithTimeCodeInSeconds:(NSTimeInterval)timecode
                                                timeType:(MIKMMCLocateTargetCommandTimeType)timeType;

@property (nonatomic, readonly) NSTimeInterval timeCodeInSeconds;
@property (nonatomic, readonly) MIKMMCLocateTargetCommandTimeType timeType;

@end

@interface MIKMutableMMCLocateTargetCommand : MIKMMCLocateTargetCommand

@property (nonatomic, readwrite) NSTimeInterval timeCodeInSeconds;
@property (nonatomic, readwrite) MIKMMCLocateTargetCommandTimeType timeType;

@property (nonatomic, readwrite) UInt8 deviceAddress;
@property (nonatomic, readwrite) MIKMIDIMachineControlDirection direction;

@property (nonatomic, strong, readwrite) NSDate *timestamp;
@property (nonatomic, readwrite) MIKMIDICommandType commandType;
@property (nonatomic, readwrite) UInt8 dataByte1;
@property (nonatomic, readwrite) UInt8 dataByte2;

@property (nonatomic, readwrite) MIDITimeStamp midiTimestamp;
@property (nonatomic, copy, readwrite, null_resettable) NSData *data;

@end

NS_ASSUME_NONNULL_END
