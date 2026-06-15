//
//  ShortcutListViewController.swift
//  Thor
//
//  Created by Alvin on 5/14/16.
//  Copyright © 2016 AlvinZhu. All rights reserved.
//

import Cocoa
import MASShortcut
import UniformTypeIdentifiers

class ShortcutListViewController: NSViewController {

    private let dragDropType = NSPasteboard.PasteboardType(rawValue: "thor.drag-drop-app")
    private let listGlassView = NSVisualEffectView()

    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var btnAdd: NSButton!
    @IBOutlet weak var btnRemove: NSButton!

    var observation: NSKeyValueObservation!

    var apps: [AppModel] {
        return AppsManager.manager.selectedApps
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor

        configureListGlass()

        tableView.backgroundColor = .clear
        tableView.enclosingScrollView?.drawsBackground = false
        tableView.enclosingScrollView?.contentView.drawsBackground = false
        tableView.enclosingScrollView?.borderType = .noBorder
        tableView.enclosingScrollView?.wantsLayer = true
        tableView.enclosingScrollView?.layer?.backgroundColor = NSColor.clear.cgColor
        tableView.usesAlternatingRowBackgroundColors = false
        tableView.selectionHighlightStyle = .none
        tableView.gridStyleMask = []
        tableView.intercellSpacing = NSSize(width: 0, height: 8)
        tableView.rowHeight = 54

        configureCommandButton(btnAdd)
        configureCommandButton(btnRemove)

        tableView.registerForDraggedTypes([dragDropType])

        observation = AppsManager.manager.observe(\.selectedApps, changeHandler: { [unowned self] (_, _) in
            self.tableView.reloadData()
        })
    }

    @IBAction func add(_ sender: AnyObject) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = true
        openPanel.allowedContentTypes = [UTType.application, UTType.applicationBundle]
        if let appDir = NSSearchPathForDirectoriesInDomains(.applicationDirectory, .localDomainMask, true).first {
            openPanel.directoryURL = URL(fileURLWithPath: appDir)
        }
        openPanel.beginSheetModal(for: view.window!, completionHandler: { (result) in
            guard result == .OK, let url = openPanel.urls.first else {
                return
            }

            let app = NSMetadataItem(url: url).flatMap { AppModel(item: $0) } ?? AppModel(url: url)
            guard let app = app else {
                return
            }

            AppsManager.manager.save(app, shortcut: nil)

            self.tableView.reloadData()
            self.tableView.scrollRowToVisible(self.apps.count - 1)
        })
    }

    @IBAction func remove(_ sender: AnyObject) {
        guard tableView.selectedRow != -1 else { return }

        let alert = NSAlert()
        alert.addButton(withTitle: "Sure".localized())
        alert.addButton(withTitle: "Cancel".localized())
        alert.messageText = "Delete this shortcut?".localized()
        alert.alertStyle = .warning

        if alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn {
            AppsManager.manager.delete(tableView.selectedRow)

            tableView.reloadData()
        }
    }

}

extension ShortcutListViewController: NSTableViewDataSource, NSTableViewDelegate {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return apps.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return apps[row]
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = NSUserInterfaceItemIdentifier(rawValue: shortcutTableCellViewIdentifier)
        let cell = tableView.makeView(withIdentifier: identifier, owner: self) as? ShortcutTableCellView
        let app = apps[row]

        cell?.configure(app.appDisplayName, icon: app.icon, shortcut: app.shortcut) { (shortcut) in
            AppsManager.manager.save(app, shortcut: shortcut)
        }

        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return GlassTableRowView()
    }

    // MARK: Drag and Drop

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        let item = NSPasteboardItem()
        item.setString(String(row), forType: dragDropType)
        return item
    }

    func tableView(_ tableView: NSTableView,
                   validateDrop info: NSDraggingInfo,
                   proposedRow row: Int,
                   proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {

        return dropOperation == .above ? .move : []
    }

    func tableView(_ tableView: NSTableView,
                   acceptDrop info: NSDraggingInfo,
                   row: Int,
                   dropOperation: NSTableView.DropOperation) -> Bool {

        guard let items = info.draggingPasteboard.pasteboardItems else { return false }

        let indexes = items.compactMap { Int($0.string(forType: dragDropType)!) }
        if !indexes.isEmpty {
            AppsManager.manager.move(with: indexes, to: row)

            var oldIndexOffset = 0
            var newIndexOffset = 0

            tableView.beginUpdates()
            for oldIndex in indexes {
                if oldIndex < row {
                    tableView.moveRow(at: oldIndex + oldIndexOffset, to: row - 1)
                    oldIndexOffset -= 1
                } else {
                    tableView.moveRow(at: oldIndex, to: row + newIndexOffset)
                    newIndexOffset += 1
                }
            }
            tableView.endUpdates()
        }

        return true
    }

    private func configureListGlass() {
        guard let scrollView = tableView.enclosingScrollView else { return }

        listGlassView.blendingMode = .withinWindow
        listGlassView.material = .contentBackground
        listGlassView.state = .active
        listGlassView.wantsLayer = true
        listGlassView.layer?.cornerRadius = 20
        listGlassView.layer?.masksToBounds = true
        listGlassView.layer?.borderColor = NSColor.white.withAlphaComponent(0.28).cgColor
        listGlassView.layer?.borderWidth = 0.7
        listGlassView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(listGlassView, positioned: .below, relativeTo: scrollView)
        NSLayoutConstraint.activate([
            listGlassView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            listGlassView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            listGlassView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            listGlassView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        ])
    }

    private func configureCommandButton(_ button: NSButton?) {
        guard let button = button else { return }

        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.imageScaling = .scaleProportionallyDown
        button.wantsLayer = true
        button.layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.34).cgColor
        button.layer?.borderColor = NSColor.white.withAlphaComponent(0.45).cgColor
        button.layer?.borderWidth = 0.8
        button.layer?.cornerRadius = 17
        button.layer?.masksToBounds = true

        if #available(macOS 10.14, *) {
            button.contentTintColor = .labelColor
        }

        button.toolTip = button == btnAdd ? "Add application".localized() : "Remove selected application".localized()
    }

}

private final class GlassTableRowView: NSTableRowView {

    override func drawBackground(in dirtyRect: NSRect) {
    }

    override func drawSelection(in dirtyRect: NSRect) {
    }

    override func drawSeparator(in dirtyRect: NSRect) {
    }

}
