//
//  ContentView.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        TestbedView()
            .frame(width: 640, height: 480)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
