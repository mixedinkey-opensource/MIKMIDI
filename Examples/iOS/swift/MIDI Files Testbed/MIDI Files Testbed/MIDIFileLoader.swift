//
//  MIDIFileLoader.swift
//  MIDI Files Testbed
//
//  Created by George Yacoub on 2016-03-11.
//  Copyright © 2016 George Yacoub. All rights reserved.
//

import Foundation
import MIKMIDI

struct MIDIFileLoader {
  private var midiFilePath:String = ""

  init(pathFromResource:String) {
    midiFilePath = loadFileFromResource(pathFromResource)
  }

  func loadMidiFileIntoMIKMIDISequence() -> MIKMIDISequence {
    do {
      return try MIKMIDISequence(
        fileAtURL: NSURL(fileURLWithPath: midiFilePath)
      )
    } catch {
      assertionFailure("Error loading MIDI file: \"\(midiFilePath)\"")
      return MIKMIDISequence()
    }
  }

  private func loadFileFromResource(midiFileName:String) -> String {
    if let midiFilePath:String = NSBundle
      .mainBundle().pathForResource(midiFileName, ofType: "mid") {
      return midiFilePath
    } else {
      assertionFailure("ERROR: please include \"\(midiFileName)\" in the project")
      return ""
    }
  }

}