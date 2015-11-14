# Change Log
All notable changes to MIKMIDI are documented in this file. This project adheres to [Semantic Versioning](http://semver.org/).

##[Unreleased]
###ADDED
- `MIKMIDISynthesizer` for general-purpose MIDI synthesis. `MIKMIDIEndpointSynthesizer` is now a subclass of `MIKMIDISynthesizer`.
- `MIKMIDISequencer` now has API for routing tracks to MIDI endpoints, synthesizers, 
or other command scheduling objects (`-(setC|c)ommandScheduler:forTrack:`)
- Nullability and Objective-C generics annotations for much nicer usage from Swift. (#39 & #108)
- API for loading soundfont files using `-[MIKMIDISynthesizer loadSoundfontFromFileAtURL:error:]`. (#47) 
- Added `MIKMIDIEvent` subclass `MIKMIDIChannelEvent` and related children (`MIKMIDIPitchBendChangeEvent`, `MIKMIDIControlChangeEvent`, etc.). (#63)
- Added `MIKMIDIChannelVoiceCommand` subclasses for remaining MIDI channel voice message types (pitch bend, polyphonic key pressure, channel pressure). (#65)
- API on `MIKMIDISequence` to control whether channels are split into individual tracks or not. (#66)
- Preliminary unit tests (still need a lot more coverage with tests).
- API on `MIKMIDISequencer` to set playback tempo (overrides sequence tempo). (#81)
- Ability to explicitly stop `MIKMIDIMappingGenerator`'s mapping via `-[MIKMIDIMappingGenerator endMapping]`. (#84)
- Looping API on `MIKMIDISequencer` (#85)
- API for syncing `MIKMIDIClock`s (see `-[MIKMIDIClock syncedClock]`). (#86)
- Ability to suspend MIDI mapping generation, then later resume right where it left off (`-[MIKMIDIMappingGenerator suspendMapping/resumeMapping]`). (#102)
- API for customizing mapping file naming. See `MIKMIDIMappingManagerDelegate`. (#114)
- `MIKMIDIConnectionManager` which implements a generic MIDI device connection manager including support for saving/restoring connection configuration to NSUserDefaults, etc. (#106)
- Other minor API additions and improvements. (#87, #89, #90, #93, #94)

###CHANGED
- `MIKMIDIEndpointSynthesizerInstrument` was renamed to `MIKMIDISynthesizerInstrument`. This **does not** break existing code, due to the use of `@compatibility_alias`
- `MIKMIDISequencer` creates and uses default synthesizers for each track, allowing a minimum of configuration for simple MIDI playback. (#34)
- `MIKMIDISequence` and `MIKMIDITrack` are now KVO compliant for most of their properties. Check documentation for specifics. (#35 & #67)
- `MIKMIDISequencer` can now send MIDI to any object that conforms to the new `MIKMIDICommandScheduler` protocol. Removes the need to use virtual endpoints for internal scheduling. (#36)
- Significantly improved performance of MIDI responder hierarchy search code, including adding (optional) caching. (#82)
- Improved `MIKMIDIDeviceManager` API to simplify device disconnection, in particular. (#109)

###FIXED
- `MIKMIDIEndpointSynthesizer` had too much reverb by default. (#38)
- `MIKMIDISequencer`'s playback would stall or drop notes when the main thread was busy/blocked. Processing is now done in the background. (#48 & #92)
- `MIKMIDIEvent` (or subclass) instances created with `alloc/init` no longer have a NULL `eventType`. (#59)
- Warnings when using MIKMIDI.framework in a Swift project. (#64)
- Bug that could cause `MIKMIDISequencer` to sometimes skip the first events in its sequence upon starting playback. (#95)
- Occasional crash (in `MIKMIDIEventIterator`) during `MIKMIDISequencer` playback. (#100)
- KVO notifications for `MIKMIDIDeviceManager`'s `availableDevices` property now includ valid `NSKeyValueChangeOld/NewKey` entries and associated values. (#112)
- Exception is no longer thrown when setting "empty" `MIKMutableMIDIMetaTimeSignatureEvent`'s numerator. (#57)
- Other minor bug fixes (#71, #83)

###DEPRECATED
This release deprecates a number of existing MIKMIDI APIs. These APIs remain available, and functional, but developers should switch to the use of their replacements as soon as possible.  

- `-[MIKMIDITrack getTrackNumber:]`. Use `trackNumber` @property on `MIKMIDITrack` instead.
- `-[MIKMIDISequence getTempo:atTimeStamp:]`. Use `-tempoAtTimeStamp:` instead.
- `-[MIKMIDISequence getTimeSignature:atTimeStamp:]`. Use `-timeSignatureAtTimeStamp:` instead.
- `doesLoop`, `numberOfLoops`, `loopDuration`, and `loopInfo` on `MIKMIDITrack`. These methods affect looping when using `MIKMIDIPlayer`, but not `MIKMIDISequencer`. Use `-[MIKMIDISequencer setLoopStartTimeStamp:endTimeStamp:]` instead.
- `-insertMIDIEvent:`, `-insertMIDIEvents:`, `-removeMIDIEvents:`, and `-clearAllEvents` on MIKMIDITrack. Use `-addEvent:`, `-removeEvent:`, `-removeAllEvents` instead.
- `-[MIKMIDIDeviceManager disconnectInput:forConnectionToken:]`. Use `-disconnectConnectionForToken:` instead.
- `-setMusicTimeStamp:withTempo:atMIDITimeStamp:`, `+secondsPerMIDITimeStamp`, `+midiTimeStampsPerTimeInterval:` on `MIKMIDIClock`. See documentation for replacement API.
- `+[MIKMIDICommand supportsMIDICommandType:]`. Use `+[MIKMIDICommand supportedMIDICommandTypes]` instead. This is only relevant when creating custom subclasses of `MIKMIDICommand`, which most MIKMIDI users do not need to do. (#57)

##[1.0.1] - 2015-04-20

###ADDED
- Support for [Carthage](https://github.com/Carthage/Carthage)
- Better error handling for `MIKMIDIClientSource/DestinationEndpoint`, particularly on iOS.
- `MIKMIDISequence` initializer methods that include an error parameter.

###CHANGED
- Improved documentation.

###FIXED
- `MIKMIDIMetronome` on iOS (8).
- `MIKMIDICommand`'s channel now defaults to 0 as it should.

###DEPRECATED
- `-[MIKMIDISequence initWithData:]`. Use `-[MIKMIDISequence initWithData:error:]`, instead.
- `+[MIKMIDISequence sequenceWithData:]`. Use `+[MIKMIDISequence sequenceWithData:error:]`, instead.
- `-[MIKMIDISequence/MIKMIDITrack setDestinationEndpoint:]`. Use API on MIKMIDISequencer instead.

##[1.0.0] - 2015-01-29
###ADDED
- MIDI Files Testbed OS X example app
- Added `MIKMIDISequence`, `MIKMIDITrack`, `MIKMIDIEvent`, etc. to support loading, creating, saving MIDI files
- API on `MIKMIDIManager` to allow obtaining only bundled or user mappings
- `MIKMIDIPlayer` for playing MIDI files
- Preliminary (experimental/incomplete) implementation of `MIKMIDISequencer` for both playback and recording
- `MIKMIDIEndpointSynthesizerInstrument` and associated instrument selection API for MIDI synthesis
- API (`MIKMIDIClientSource/DestinationEndpoint`) for creating virtual MIDI endpoints
- iOS framework target.

###CHANGED

- Improved README.

###FIXED
- Fixed bug where sending a large number of MIDI messages at a time could fail.
- `MIKMIDIMapping` save/load is now supported on iOS.
- Warnings when building for iOS.

##[0.9.2] - 2014-06-13
###ADDED
- Added `MIKMIDIEndpointSynthesizer` for synthesizing incoming MIDI (OS X only for now).
- Added Cocoapods podspec file to repository.

###FIXED
- `MIKMIDIInputPort` can parse multiple MIDI messages out of a single packet.

##[0.9.1] - 2014-05-24
###FIXED
Minor documentation typo fixes.

##[0.9.0] - 2014-05-16
###ADDED
Initial release