//
//  MIKMIDI.h
//  MIKMIDI
//
//  Created by Andrew Madsen on 6/2/13.
//  Copyright (c) 2013 Mixed In Key. All rights reserved.
//

/** Umbrella header for MIKMIDI public interface. */

// Core MIDI object wrapper
#import <MIKMIDI/MIKMIDIObject.h>

// MIDI port
#import <MIKMIDI/MIKMIDIPort.h>
#import <MIKMIDI/MIKMIDIInputPort.h>
#import <MIKMIDI/MIKMIDIOutputPort.h>

// MIDI Device support
#import <MIKMIDI/MIKMIDIDevice.h>
#import <MIKMIDI/MIKMIDIDeviceManager.h>
#import <MIKMIDI/MIKMIDIConnectionManager.h>

#import <MIKMIDI/MIKMIDIEntity.h>

// Endpoints
#import <MIKMIDI/MIKMIDIEndpoint.h>
#import <MIKMIDI/MIKMIDIDestinationEndpoint.h>
#import <MIKMIDI/MIKMIDISourceEndpoint.h>
#import <MIKMIDI/MIKMIDIClientDestinationEndpoint.h>
#import <MIKMIDI/MIKMIDIClientSourceEndpoint.h>

// MIDI Commands/Messages
#import <MIKMIDI/MIKMIDICommand.h>
#import <MIKMIDI/MIKMIDIChannelVoiceCommand.h>
#import <MIKMIDI/MIKMIDINoteCommand.h>
#import <MIKMIDI/MIKMIDIChannelPressureCommand.h>
#import <MIKMIDI/MIKMIDIControlChangeCommand.h>
#import <MIKMIDI/MIKMIDIProgramChangeCommand.h>
#import <MIKMIDI/MIKMIDIPitchBendChangeCommand.h>
#import <MIKMIDI/MIKMIDINoteOnCommand.h>
#import <MIKMIDI/MIKMIDINoteOffCommand.h>
#import <MIKMIDI/MIKMIDIPolyphonicKeyPressureCommand.h>
#import <MIKMIDI/MIKMIDISystemExclusiveCommand.h>
#import <MIKMIDI/MIKMIDISystemMessageCommand.h>
#import <MIKMIDI/MIKMIDISystemKeepAliveCommand.h>
#import <MIKMIDI/MIKMIDIMachineControl.h> // Includes many individual MMC command types

// MIDI Sequence/File support
#import <MIKMIDI/MIKMIDISequence.h>
#import <MIKMIDI/MIKMIDITrack.h>

// MIDI Events
#import <MIKMIDI/MIKMIDIEvent.h>
#import <MIKMIDI/MIKMIDITempoEvent.h>
#import <MIKMIDI/MIKMIDINoteEvent.h>

// Channel Events
#import <MIKMIDI/MIKMIDIChannelEvent.h>
#import <MIKMIDI/MIKMIDIPolyphonicKeyPressureEvent.h>
#import <MIKMIDI/MIKMIDIControlChangeEvent.h>
#import <MIKMIDI/MIKMIDIProgramChangeEvent.h>
#import <MIKMIDI/MIKMIDIChannelPressureEvent.h>
#import <MIKMIDI/MIKMIDIPitchBendChangeEvent.h>

// Meta Events
#import <MIKMIDI/MIKMIDIMetaEvent.h>
#import <MIKMIDI/MIKMIDIMetaCopyrightEvent.h>
#import <MIKMIDI/MIKMIDIMetaCuePointEvent.h>
#import <MIKMIDI/MIKMIDIMetaInstrumentNameEvent.h>
#import <MIKMIDI/MIKMIDIMetaKeySignatureEvent.h>
#import <MIKMIDI/MIKMIDIMetaLyricEvent.h>
#import <MIKMIDI/MIKMIDIMetaMarkerTextEvent.h>
#import <MIKMIDI/MIKMIDIMetaSequenceEvent.h>
#import <MIKMIDI/MIKMIDIMetaTextEvent.h>
#import <MIKMIDI/MIKMIDIMetaTimeSignatureEvent.h>
#import <MIKMIDI/MIKMIDIMetaTrackSequenceNameEvent.h>

// Sequencing and Synthesis
#import <MIKMIDI/MIKMIDISequencer.h>
#import <MIKMIDI/MIKMIDIMetronome.h>
#import <MIKMIDI/MIKMIDIClock.h>
#import <MIKMIDI/MIKMIDIPlayer.h>
#import <MIKMIDI/MIKMIDIEndpointSynthesizer.h>

// MIDI Mapping
#import <MIKMIDI/MIKMIDIMapping.h>
#import <MIKMIDI/MIKMIDIMappingItem.h>
#import <MIKMIDI/MIKMIDIMappableResponder.h>
#import <MIKMIDI/MIKMIDIMappingManager.h>
#import <MIKMIDI/MIKMIDIMappingGenerator.h>

// Intra-application MIDI command routing
#import <MIKMIDI/NSUIApplication+MIKMIDI.h>
#import <MIKMIDI/MIKMIDIResponder.h>
#import <MIKMIDI/MIKMIDICommandThrottler.h>

// Utilities
#import <MIKMIDI/MIKMIDIUtilities.h>
#import <MIKMIDI/MIKMIDIErrors.h>
#import <MIKMIDI/MIKMIDICompilerCompatibility.h>
