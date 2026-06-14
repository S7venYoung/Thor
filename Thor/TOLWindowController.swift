//
//  TOLWindowController.swift
//  Thor
//
//  Created by AlvinZhu on 4/18/16.
//  Copyright © 2016 AlvinZhu. All rights reserved.
//

import Cocoa

class TOLWindowController: NSWindowController {

    var titleView       = TitleView()
    private let glassBackgroundView = NSVisualEffectView()
    var identifiers     = [NSToolbarItem.Identifier]()
    var items           = [NSToolbarItem.Identifier: NSToolbarItem]()
    var viewControllers = [String: NSViewController]()

    override func windowDidLoad() {
        super.windowDidLoad()

        configureWindowAppearance()

        let toolbar = NSToolbar(identifier: "toolbar")
        toolbar.delegate = self
        toolbar.showsBaselineSeparator = false
        if #available(macOS 11.0, *) {
            toolbar.displayMode = .iconOnly
        }
        window?.toolbar = toolbar

        // title

        titleView.toggleCallback = toggleViewControllers

        let titleItem = NSToolbarItem(itemIdentifier: titleViewIdentifier)
        titleItem.view = titleView

        identifiers.append(titleViewIdentifier)
        items[titleViewIdentifier] = titleItem
        toolbar.insertItem(withItemIdentifier: titleViewIdentifier, at: 0)

        // space

        let spaceItem = NSToolbarItem(itemIdentifier: NSToolbarItem.Identifier.flexibleSpace)

        identifiers.append(NSToolbarItem.Identifier.flexibleSpace)
        items[NSToolbarItem.Identifier.flexibleSpace] = spaceItem
        toolbar.insertItem(withItemIdentifier: NSToolbarItem.Identifier.flexibleSpace, at: 0)
    }

    override func keyDown(with theEvent: NSEvent) {
        let key = theEvent.charactersIgnoringModifiers
        if theEvent.modifierFlags.contains(NSEvent.ModifierFlags.command) && key == "w" {
            close()
        } else {
            super.keyDown(with: theEvent)
        }
    }

    func insert(_ titleItem: TitleViewItem, viewController: NSViewController) {
        viewControllers[titleItem.identifier!.rawValue] = viewController

        titleView.insert(titleItem)
        titleView.toggle(titleView.items.first!)
    }

    private func toggleViewControllers(_ item: TitleViewItem) {
        guard let contentViewController = contentViewController else {
            return
        }

        if contentViewController.children.count > 0 {
            contentViewController.children.forEach { $0.removeFromParent() }
        }

        glassBackgroundView.subviews.forEach { $0.removeFromSuperview() }

        if glassBackgroundView.superview == nil {
            installGlassBackground(in: contentViewController.view)
        }

        if let viewController = viewControllers[item.identifier!.rawValue] {
            contentViewController.insertChild(viewController, at: 0)
            glassBackgroundView.addSubview(viewController.view)
            viewController.view.frame = glassBackgroundView.bounds
            viewController.view.autoresizingMask = [.width, .height]
        }
    }

    private func configureWindowAppearance() {
        guard let window = window else { return }

        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true

        if #available(macOS 11.0, *) {
            window.toolbarStyle = .unifiedCompact
        }

        window.contentView?.wantsLayer = true
        window.contentView?.layer?.cornerRadius = 18
        window.contentView?.layer?.masksToBounds = true
    }

    private func installGlassBackground(in rootView: NSView) {
        rootView.wantsLayer = true
        rootView.layer?.backgroundColor = NSColor.clear.cgColor

        glassBackgroundView.blendingMode = .behindWindow
        glassBackgroundView.material = .underWindowBackground
        glassBackgroundView.state = .active
        glassBackgroundView.wantsLayer = true
        glassBackgroundView.layer?.cornerRadius = 18
        glassBackgroundView.layer?.masksToBounds = true
        glassBackgroundView.translatesAutoresizingMaskIntoConstraints = false

        rootView.addSubview(glassBackgroundView, positioned: .below, relativeTo: nil)
        NSLayoutConstraint.activate([
            glassBackgroundView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            glassBackgroundView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            glassBackgroundView.topAnchor.constraint(equalTo: rootView.topAnchor),
            glassBackgroundView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor)
        ])
    }

}

extension TOLWindowController: NSToolbarDelegate {

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return identifiers
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        return identifiers
    }

    func toolbar(_ toolbar: NSToolbar,
                 itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        return items[itemIdentifier]
    }

}

// MARK: -

class TitleView: NSView {

    var items = [TitleViewItem]()
    var toggleCallback: ((_ item: TitleViewItem) -> Void)?

    func insert(_ item: TitleViewItem) {
        items.append(item)
        items.forEach { $0.removeFromSuperview() }
        for (idx, item) in items.enumerated() {
            addSubview(item)

            item.target = self
            item.action = #selector(TitleView.toggle(_:))
            item.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                item.leftAnchor.constraint(equalTo: leftAnchor, constant: CGFloat(idx) * titleItemWidth),
                item.topAnchor.constraint(equalTo: topAnchor),
                item.widthAnchor.constraint(equalToConstant: titleItemWidth),
                item.heightAnchor.constraint(equalToConstant: titleItemHeight)
            ])
        }

        frame = CGRect(x: 0, y: 0, width: CGFloat(items.count) * titleItemWidth, height: titleItemHeight)
    }

    @objc func toggle(_ sender: TitleViewItem) {
        items.forEach { $0.state = ($0 != sender) ? .on : .off }

        toggleCallback?(sender)
    }
}

// MARK: -

class TitleViewItem: NSButton {

    var activeImage: NSImage? {
        get { return image }
        set { image = newValue }
    }

    var inactiveImage: NSImage? {
        get { return alternateImage }
        set { alternateImage = newValue }
    }

    init(itemIdentifier: String) {
        super.init(frame: NSRect.zero)

        identifier = NSUserInterfaceItemIdentifier(rawValue: itemIdentifier)
        isBordered = false
        bezelStyle = .rounded
        imagePosition = .imageOnly
        setButtonType(.toggle)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
