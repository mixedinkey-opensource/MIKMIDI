//
//  ViewController.swift
//  MIDI to Audio iOS
//
//  Created by Sasha Ivanov on 2016-12-24.
//  Copyright © 2016 madebysasha. All rights reserved.

//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the
//	"Software"), to deal in the Software without restriction, including
//	without limitation the rights to use, copy, modify, merge, publish,
//	distribute, sublicense, and/or sell copies of the Software, and to
//	permit persons to whom the Software is furnished to do so, subject to
//	the following conditions:
//
//	The above copyright notice and this permission notice shall be included
//	in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
//	OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
//	MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
//	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
//	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
//	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
//	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


import UIKit
import AVFoundation
import MIKMIDI

class ViewController: UIViewController {

    
    
    var midiUrl:URL?
    var soundfontUrl:URL?
    var sequencer:MIKMIDISequencer?
    
    var audioUrl:URL?
    var audioPlayer:AVPlayer?
    
    @IBOutlet weak var playOriginalButton: UIButton!
    @IBOutlet weak var convertToAudioFileButton: UIButton!
    @IBOutlet weak var playConvertedAudioFileButton: UIButton!
    
    @IBAction func playOriginalButtonPressed(_ sender: Any) {
        
        // Play the sequencer
        sequencer?.startPlayback()
        
    }
    
    @IBAction func convertToAudioFileButtonPressed(_ sender: Any) {
        
        // Create the MIKMIDI Audio Exporter
        let audioExporter = MIKMIDIToAudioExporter(midiFileAt: midiUrl)
        
        // Add the soundfont to the Audio Exporter (NEW from macOS Example)
        audioExporter?.addSoundfont(soundfontUrl)
        
        // Render the MIDI file as a CAF file with the added soundfont
        audioExporter?.exportWithSoundfontToAudioFile(completionHandler: { (audioOutputUrl, error) in
            
            // Check if there was an error durring the export
            if (audioOutputUrl == nil){
                if((error) != nil){
                    NSLog(error as! String)
                    print("Audio Conversion Failed")
                }
            }
                
                // Otherwise save the output url and enable the Play Converted Audio button
            else{
                self.audioUrl = audioOutputUrl
                self.playConvertedAudioFileButton.isEnabled = true
            }
        })
    }
    
    @IBAction func playConvertedButtonPressed(_ sender: Any) {
        
        // Create an AV Audio Player to playback the converted file
        audioPlayer = AVPlayer(url: audioUrl!)
        
        // Play the converted file
        audioPlayer?.play()
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 1. Disable the Play Converted Audio button. (Will enable when the convert button is pressed)
        playConvertedAudioFileButton.isEnabled = false
        
        // 2. Set the URLs of the files we want to use for playback (midi file and soundfont file)
        midiUrl = Bundle.main.url(forResource: "TheOriginal", withExtension: "mid")
        soundfontUrl = Bundle.main.url(forResource: "Stereo Piano",  withExtension: ".sf2")
        
        // 3. Setup the MIKMIDI Sequencer for Playing Back Original Midi File
        do{
            // Create a MIKMIDI Sequence from the midi file
            let sequence = try MIKMIDISequence(fileAt: midiUrl!)
            
            // Create a MIKMIDI Sequencer from the sequence
            sequencer = MIKMIDISequencer(sequence: sequence)
            
            // Use the Soundfont File to set the Synth for each Track in the Sequence.
            for track in sequence.tracks{
                let synth = sequencer?.builtinSynthesizer(for: track)
                try synth!.loadSoundfontFromFile(at: soundfontUrl!)
            }
        }
        catch{
            print("Unable to Create Sequencer")
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    


}

