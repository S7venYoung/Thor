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
    private let rowBackgroundView = NSVisualEffectView()

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()

        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
        configureRowBackground()
        configureShortcutCapsule()
    }

    func configure(_ name: String,
                   icon: NSImage?,
                   shortcut: MASShortcut?,
                   shortcutValueChange: @escaping (MASShortcut?) -> Void) {
        textField?.stringValue = name
        textField?.font = NSFont.systemFont(ofSize: 14.5, weight: .medium)
        textField?.textColor = .labelColor
        imageView?.image = icon

        shortcutView.shortcutValueChange = nil
        shortcutView.shortcutValue = shortcut
        shortcutView.shortcutValueChange = { sender in
            shortcutValueChange(sender?.shortcutValue)
        }
    }

    private func configureRowBackground() {
        guard rowBackgroundView.superview == nil else { return }

        rowBackgroundView.blendingMode = .withinWindow
        rowBackgroundView.material = .contentBackground
        rowBackgroundView.state = .active
        rowBackgroundView.wantsLayer = true
        rowBackgroundView.layer?.cornerRadius = 14
        rowBackgroundView.layer?.masksToBounds = true
        rowBackgroundView.layer?.borderColor = NSColor.white.withAlphaComponent(0.22).cgColor
        rowBackgroundView.layer?.borderWidth = 0.6
        rowBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        addSubview(rowBackgroundView, positioned: .below, relativeTo: nil)
        NSLayoutConstraint.activate([
            rowBackgroundView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            rowBackgroundView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rowBackgroundView.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            rowBackgroundView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -3)
        ])
    }

    private func configureShortcutCapsule() {
        shortcutView.wantsLayer = true
        shortcutView.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.26).cgColor
        shortcutView.layer?.borderColor = NSColor.white.withAlphaComponent(0.30).cgColor
        shortcutView.layer?.borderWidth = 0.7
        shortcutView.layer?.cornerRadius = 12
        shortcutView.layer?.masksToBounds = true
    }

}
