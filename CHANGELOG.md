# Change Log
All notable changes to MIKMIDI are documented in this file. This project adheres to [Semantic Versioning](http://semver.org/).

##[Unreleased]
This section is for changes commited to the MIKMIDI repository, but not yet included in an official release.

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
- `MIKMIDISynthesizer` and associated instrument selection API for MIDI synthesis
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