//
//  boringNotchApp.swift
//  boringNotchApp
//
//  Created by Harsh Vardhan  Goswami  on 02/08/24.
//  Editied by Eliomar Rodriguez on 01/12/25.
//

import Defaults
import Sparkle
import SwiftUI

@main
struct DynamicNotchApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    
    var appDelegate
    @Default(.menubarIcon) var showMenuBarIcon
    
    let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
        SettingsWindowController.shared.setUpdaterController(updaterController)
    }

    var body: some Scene {
        MenuBarExtra(
            "boring.notch",
            systemImage: "sparkle",
            isInserted : $showMenuBarIcon
        ) {
            Button("Settings") {
                SettingsWindowController.shared.showWindow()
            }
            .keyboardShortcut(KeyEquivalent(","), modifiers: .command)
            
            CheckForUpdatesView(updater: updaterController.updater)
            Divider()
            
            Button("Restart Boring Notch") {
                ApplicationRelauncher.restart()
            }
            
            Button("Quit", role: .destructive) {
                NSApplication.shared.terminate(self)
            }
            .keyboardShortcut(KeyEquivalent("Q"), modifiers: .command)
        }
    }
}
