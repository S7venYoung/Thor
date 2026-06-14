//
//  ShortcutTableCellView.swift
//  Thor
//
//  Created by Alvin on 6/1/16.
//  Copyright © 2016 AlvinZhu. All rights reserved.
//

import Cocoa
import MASShortcut

class ShortcutTableCellView: NSTableCellView {

    @IBOutlet weak var shortcutView: MASShortcutView!

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }

    func configure(_ name: String,
                   icon: NSImage?,
                   shortcut: MASShortcut?,
                   shortcutValueChange: @escaping (MASShortcut?) -> Void) {
        textField?.stringValue = name
        imageView?.image = icon

        shortcutView.shortcutValueChange = nil
        shortcutView.shortcutValue = shortcut
        shortcutView.shortcutValueChange = { sender in
            shortcutValueChange(sender?.shortcutValue)
        }
    }

}
