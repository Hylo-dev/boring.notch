//
//  AppDelegate.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 02/08/24.
//  Editied by Eliomar Rodriguez on 01/12/25.
//

import AppKit
import Defaults
import KeyboardShortcuts
import SwiftUI

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private let windowManager = WindowManager.shared
    private var onboardingWindowController: NSWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Avvia gestione finestre
        windowManager.refreshWindows()
            
        setupShortcuts()
        checkOnboarding() // Usa la funzione safe creata sopra
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowManager.closeAll()
        MusicManager.shared.destroy()
        XPCHelperClient.shared.stopMonitoringAccessibilityAuthorization()
    }
    
    private func setupShortcuts() {
        KeyboardShortcuts.onKeyDown(for: .toggleSneakPeek) {
            Task { @MainActor in
                let coordinator = BoringViewCoordinator.shared
                
                if Defaults[.sneakPeekStyles] == .inline {
                    coordinator.toggleExpandingView(
                        status: !coordinator.expandingView.isShow,
                        type: .music
                    )
                    
                } else {
                    coordinator.toggleSneakPeek(
                        type: .music,
                        show: !coordinator.sneakPeek.isShow,
                        duration: 3.0
                    )
                }
            }
        }

        KeyboardShortcuts.onKeyDown(for: .toggleNotchOpen) {
            Task { @MainActor in
                WindowManager.shared.toggleNotchUnderMouse(mouseLocation: NSEvent.mouseLocation)
            }
        }
    }

    private func playWelcomeSound() {
        let audioPlayer = AudioPlayer()
        audioPlayer.play(fileName: "boring", fileExtension: "m4a")
    }
    
    private func showOnboardingWindow(step: OnboardingStep = .welcome) {
        if onboardingWindowController == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 600),
                styleMask: [.titled, .fullSizeContentView],
                backing: .buffered, defer: false
            )
            window.center()
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            
            window.contentView = NSHostingView(
                rootView: OnboardingView(
                    step: step,
                    onFinish: {
                        window.close()
                        NSApp.deactivate()
                    },
                    onOpenSettings: {
                        window.close()
                        SettingsWindowController.shared.showWindow()
                    }
                )
            )
            onboardingWindowController = NSWindowController(window: window)
        }
        
        NSApp.activate(ignoringOtherApps: true)
        onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
    }
    
    private func checkOnboarding() {
        Task { @MainActor in
            if BoringViewCoordinator.shared.firstLaunch {
                self.showOnboardingWindow()
                self.playWelcomeSound()
                
            } else if MusicManager.shared.isNowPlayingDeprecated && Defaults[.mediaController] == .nowPlaying {
                self.showOnboardingWindow(step: .musicPermission)
            }
        }
    }
}
