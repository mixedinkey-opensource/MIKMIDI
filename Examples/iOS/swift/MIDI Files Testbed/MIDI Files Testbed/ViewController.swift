//
//  ViewController.swift
//  MIDI Files Testbed
//
//  Created by George Yacoub on 2016-03-11.
//  Copyright © 2016 George Yacoub. All rights reserved.
//

import UIKit
import MIKMIDI
import NSLogger

class ViewController: UIViewController, MIKMIDIConnectionManagerDelegate {

  let deviceManager:MIKMIDIDeviceManager = MIKMIDIDeviceManager.sharedDeviceManager()
  var connectionToken:AnyObject?

  override func viewDidLoad() {
    super.viewDidLoad()

    MIDINetworkSession.defaultSession().enabled = true
    MIDINetworkSession.defaultSession().connectionPolicy = MIDINetworkConnectionPolicy.Anyone

    LoggerStart(LoggerGetDefaultLogger())

//    let connectionManager = MIKMIDIConnectionManager(
//      name: "com.mixedinkey.MIDITestbed.ConnectionManager",
//      delegate: self) { (source:MIKMIDISourceEndpoint, commands:[MIKMIDICommand]) -> Void in
//        for command in commands {
//          self.LogMessage(command)
//        }
//    }
//    connectionManager.automaticallySavesConfiguration = true

//    let fileLoader:MIDIFileLoader = MIDIFileLoader(pathFromResource: "bach-invention-01")
//    let sequence:MIKMIDISequence = fileLoader.loadMidiFileIntoMIKMIDISequence()

    deviceManager.addObserver(self,
      forKeyPath: "availableDevices",
      options: NSKeyValueObservingOptions.Initial,
      context: nil
    )
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }

  override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?,
    change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
    if keyPath == "availableDevices" {
      LogMessage(object)
      LogMessage(change)
      connectToDevices()
    }
  }

  private func connectToDevices() {
    let nonBluetoothNetworkDevices = deviceManager.availableDevices.filter(nonBluetoothNetworkFilter)
    var device:MIKMIDIDevice?

    if nonBluetoothNetworkDevices.count > 0 {
      device = nonBluetoothNetworkDevices.first
    } else {
      device = deviceManager.availableDevices.filter(networkDeviceFilter).first
    }

    connectToDevice(device)
  }

  private func connectToDevice(device:MIKMIDIDevice?) {
    disconnectFromOldDevice()

    if device == nil {
      return
    }

    do {
      self.connectionToken = try deviceManager.connectDevice(device!, eventHandler: {
        (source:MIKMIDISourceEndpoint, commands:[MIKMIDICommand]) -> Void in
        self.LogMessage(source)
        self.LogMessage(commands)
      })
    } catch {
      LogMessage("can't connect to \(device)")
    }
  }

  private func disconnectFromOldDevice() {
    if connectionToken != nil {
      deviceManager.disconnectConnectionForToken(connectionToken!)
    }
  }

  private func nonBluetoothNetworkFilter(device:MIKMIDIDevice) -> Bool {
    return device.name != "Bluetooth" && device.name != "Network"
  }

  private func networkDeviceFilter(device:MIKMIDIDevice) -> Bool {
    return device.name == "Network"
  }

  private func LogMessage(format: AnyObject?, args: CVarArgType...) {
    LogMessage_va("1", 0, "\(format)", getVaList(args))
  }

}
