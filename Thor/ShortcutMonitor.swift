//
//  ShortcutMonitor.swift
//  Thor
//
//  Created by Alvin on 5/14/16.
//  Copyright © 2016 AlvinZhu. All rights reserved.
//

import Foundation
import Cocoa
import MASShortcut

struct ShortcutMonitor {

    static func register() {
        let apps = AppsManager.manager.selectedApps
        for app in apps where app.shortcut != nil {
            MASShortcutMonitor.shared().register(app.shortcut, withAction: { [app] in
                guard defaults[.EnableShortcut] else { return }

                guard let targetAppIdentifier = Bundle(url: app.appBundleURL)?.bundleIdentifier else {
                    open(app)
                    return
                }

                if let frontmostAppIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier,
                   frontmostAppIdentifier == targetAppIdentifier {
                    NSRunningApplication.runningApplications(withBundleIdentifier: targetAppIdentifier).first?.hide()
                    return
                }

                if let runningApplication = NSRunningApplication.runningApplications(
                    withBundleIdentifier: targetAppIdentifier
                ).first {
                    runningApplication.unhide()
                    runningApplication.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                    return
                }

                open(app)
            })
        }
    }

    private static func open(_ app: AppModel) {
        if #available(macOS 10.15, *) {
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = true
            NSWorkspace.shared.openApplication(at: app.appBundleURL,
                                               configuration: configuration) { runningApplication, error in
                if let error = error {
                    NSLog("ERROR: \(error)")
                    return
                }

                runningApplication?.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
            }
        } else {
            NSWorkspace.shared.launchApplication(app.appBundleURL.lastPathComponent)
        }
    }

    static func unregister() {
        let apps = AppsManager.manager.selectedApps
        for app in apps where app.shortcut != nil {
            MASShortcutMonitor.shared().unregisterShortcut(app.shortcut)
        }
    }

}
