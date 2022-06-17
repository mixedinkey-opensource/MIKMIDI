//
//  TextView.swift
//  MIDI Testbed (SwiftUI)
//
//  Created by James Ranson on 12/19/20.
//

import Foundation
import SwiftUI

// a scrollable, read-only, clipboard-copyable text field for SwiftUI
struct TextView: NSViewRepresentable {

    @Binding var text: String

    let scrollView: NSScrollView = NSTextView.scrollableTextView()

    init(text: Binding<String>) {
        self._text = text
    }

    func makeNSView(context: Context) -> NSScrollView {

        let textView = scrollView.documentView as! NSTextView
        textView.isSelectable = true
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.isRichText = false
        textView.importsGraphics = false
        textView.isEditable = false
        textView.drawsBackground = false
        textView.autoresizingMask = [.width]

        scrollView.hasVerticalScroller = true
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ uiView: NSScrollView, context: Context) {
        let tv = uiView.documentView as! NSTextView
        tv.string = text
        tv.scrollToEndOfDocument(nil)
    }
}
