//
//  MIKMIDISynthesizer_SubclassMethods.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 2/26/15.
//  Copyright (c) 2015 Mixed In Key. All rights reserved.
//

#import "MIKMIDISynthesizer.h"

@interface MIKMIDISynthesizer ()

- (BOOL)sendBankSelectAndProgramChangeForInstrumentID:(MusicDeviceInstrumentID)instrumentID error:(NSError **)error;

@property (nonatomic, readwrite) AudioUnit instrumentUnit;

@end