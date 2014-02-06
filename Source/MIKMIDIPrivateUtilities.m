//
//  MIKMIDIPrivateUtilities.m
//  MIKMIDI
//
//  Created by Andrew Madsen on 11/11/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

#import "MIKMIDIPrivateUtilities.h"
#import "MIKMIDIChannelVoiceCommand.h"
#import "MIKMIDIControlChangeCommand.h"
#import "MIKMIDINoteOnCommand.h"

NSUInteger MIKMIDIControlNumberFromCommand(MIKMIDIChannelVoiceCommand *command)
{
	if ([command respondsToSelector:@selector(controllerNumber)]) return [(id)command controllerNumber];
	if ([command respondsToSelector:@selector(note)]) return [(MIKMIDINoteOnCommand *)command note];
	
	return (command.dataByte1 & 0x7F);
}

float MIKMIDIControlValueFromChannelVoiceCommand(MIKMIDIChannelVoiceCommand *command)
{
	if ([command respondsToSelector:@selector(isFourteenBitCommand)] &&
		[(MIKMIDIControlChangeCommand *)command isFourteenBitCommand]) {
		 return (float)[(MIKMIDIControlChangeCommand *)command fourteenBitValue] / 127.0f;
	}
	
	return (float)command.value;
}