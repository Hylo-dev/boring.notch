//
//  BoringViewCoordinator.swift
//  boringNotch
//
//  Created by Alexander on 2024-11-20.
//

import AppKit
import Combine
import Defaults
import SwiftUI

// MARK: - Enums

enum SneakContentType: String, Codable {
    case brightness, volume, backlight, music, mic, battery, download, unknown
}

enum BrowserType: String, Codable {
    case chromium, safari
}

// MARK: - Structs

struct sneakPeek {
    var type  : SneakContentType = .music
    var isShow: Bool             = false
    var value : CGFloat          = 0
    var icon  : String           = ""
    
    var isMediaOrBattery: Bool { type == .music || type == .battery }
}

struct ExpandedItem: Equatable {
    var type   : SneakContentType = .unknown
    var isShow : Bool             = false
    var value  : CGFloat          = 0
    var browser: BrowserType      = .chromium
}

enum StatusContentType {
    case showBattery
    case showMusic
}

struct SharedSneakPeek: Codable {
    var show : Bool
    var type : String
    var value: String
    var icon : String
}

@MainActor
class BoringViewCoordinator: ObservableObject {
    
    static let shared = BoringViewCoordinator()

    @Published
    var currentView: NotchViews = .home
    
    @Published
    var helloAnimationRunning: Bool = false
    
    private var sneakPeekDispatch: DispatchWorkItem?
    private var expandingViewDispatch: DispatchWorkItem?
    private var hudEnableTask: Task<Void, Never>?
    
    /// Legacy storage for migration
    @AppStorage("preferred_screen_name")
    private var legacyPreferredScreenName: String?
    
    @AppStorage("firstLaunch") var firstLaunch: Bool = true
    @AppStorage("showWhatsNew") var showWhatsNew: Bool = true
    @AppStorage("musicLiveActivityEnabled") var musicLiveActivityEnabled: Bool = true
    @AppStorage("currentMicStatus") var currentMicStatus: Bool = true

    @AppStorage("alwaysShowTabs")
    var alwaysShowTabs: Bool = true {
        didSet {
            if !alwaysShowTabs {
                
                openLastTabByDefault = false
                if ShelfStateViewModel.shared.isEmpty || !Defaults[.openShelfByDefault] {
                    currentView = .home
                }
            }
        }
    }

    @AppStorage("openLastTabByDefault")
    var openLastTabByDefault: Bool = false {
        didSet {
            if openLastTabByDefault {
                alwaysShowTabs = true
            }
        }
    }
    
    @Default(.hudReplacement)
    var hudReplacement: Bool
    
    // New UUID-based storage
    @AppStorage("preferred_screen_uuid")
    var preferredScreenUUID: String? {
        didSet {
            if let uuid = preferredScreenUUID {
                selectedScreenUUID = uuid
            }
            NotificationCenter.default.post(
                name: Notification.Name.selectedScreenChanged,
                object: nil
            )
        }
    }

    @Published var selectedScreenUUID: String = NSScreen.main?.displayUUID ?? ""

    @Published var optionKeyPressed: Bool = true
    
    private var accessibilityObserver: Any?
    private var hudReplacementCancellable: AnyCancellable?

    private init() {
        
        // Perform migration from name-based to UUID-based storage
        if preferredScreenUUID == nil, let legacyName = legacyPreferredScreenName {
            // Try to find screen by name and migrate to UUID
            if let screen = NSScreen.screens.first(
                where: { $0.localizedName == legacyName }
                
            ), let uuid = screen.displayUUID {
                preferredScreenUUID = uuid
                NSLog("✅ Migrated display preference from name '\(legacyName)' to UUID '\(uuid)'")
                
            } else {
                // Fallback to main screen if legacy screen not found
                preferredScreenUUID = NSScreen.main?.displayUUID
                NSLog("⚠️ Could not find display named '\(legacyName)', falling back to main screen")
            }
            
            // Clear legacy value after migration
            legacyPreferredScreenName = nil
            
        } else if preferredScreenUUID == nil {
            // No legacy value, use main screen
            preferredScreenUUID = NSScreen.main?.displayUUID
        }
        
        selectedScreenUUID = preferredScreenUUID ?? NSScreen.main?.displayUUID ?? ""
        // Observe changes to accessibility authorization and react accordingly
        accessibilityObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name.accessibilityAuthorizationChanged,
            object: nil,
            queue: .main
        ) { _ in
            Task { @MainActor in
                if Defaults[.hudReplacement] {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }

        // Observe changes to hudReplacement
        hudReplacementCancellable = Defaults.publisher(.hudReplacement)
            .sink { [weak self] change in
                Task { @MainActor in
                    guard let self = self else { return }

                    self.hudEnableTask?.cancel()
                    self.hudEnableTask = nil

                    if change.newValue {
                        self.hudEnableTask = Task { @MainActor in
                            let granted = await XPCHelperClient.shared.ensureAccessibilityAuthorization(promptIfNeeded: true)
                            if Task.isCancelled { return }

                            if granted {
                                await MediaKeyInterceptor.shared.start()
                                
                            } else {
                                Defaults[.hudReplacement] = false
                            }
                        }
                    } else {
                        MediaKeyInterceptor.shared.stop()
                    }
                }
            }

        Task { @MainActor in
            helloAnimationRunning = firstLaunch

            if Defaults[.hudReplacement] {
                let authorized = await XPCHelperClient.shared.isAccessibilityAuthorized()
                
                if !authorized {
                    Defaults[.hudReplacement] = false
                    
                } else {
                    await MediaKeyInterceptor.shared.start(promptIfNeeded: false)
                }
            }
        }
    }
    
    @objc func sneakPeekEvent(_ notification: Notification) {
        let decoder = JSONDecoder()
        if let decodedData = try? decoder.decode(
            SharedSneakPeek.self, from: notification.userInfo?.first?.value as! Data)
        {

            let formatter = NumberFormatter()
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.numberStyle = .decimal
            let value = CGFloat((formatter.number(from: decodedData.value) ?? 0.0).floatValue)
            let icon = decodedData.icon

            print("Decoded: \(decodedData), Parsed value: \(value)")

            toggleSneakPeek(
                type: SneakContentType(rawValue: decodedData.type) ?? .battery,
                show: decodedData.show,
                value: value,
                icon: icon
            )

        } else {
            print("Failed to decode JSON data")
        }
    }

    func toggleSneakPeek(
        type: SneakContentType,
        show: Bool,
        duration: TimeInterval = 1.5,
        value: CGFloat = 0,
        icon: String = ""
    ) {
        sneakPeekDuration = duration
        
        if type != .music {
            if !Defaults[.hudReplacement] {
                return
            }
        }
        
        Task { @MainActor in
            withAnimation(.smooth) {
                self.sneakPeek.type  = type
                self.sneakPeek.value = value
                self.sneakPeek.icon  = icon
            }
        }

        if type == .mic {
            currentMicStatus = value == 1
        }
    }

    private var sneakPeekDuration: TimeInterval = 1.5
    private var sneakPeekTask: Task<Void, Never>?

    // Helper function to manage sneakPeek timer using Swift Concurrency
    private func scheduleSneakPeekHide(after duration: TimeInterval) {
        sneakPeekTask?.cancel()

        sneakPeekTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(duration))
            guard let self = self, !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation {
                    self.toggleSneakPeek(
                        type: .music,
                        show: true
                    )
                    
                    self.sneakPeekDuration = 1.5
                }
            }
        }
    }

    @Published
    var sneakPeek: sneakPeek = .init() {
        didSet {
            if sneakPeek.isShow {
                scheduleSneakPeekHide(after: sneakPeekDuration)
                
            } else { sneakPeekTask?.cancel() }
        }
    }
    
    @Published
    var expandingView: ExpandedItem = .init()

    func toggleExpandingView(
        status: Bool,
        type: SneakContentType,
        value: CGFloat = 0,
        browser: BrowserType = .chromium
    ) {
        Task { @MainActor in
            withAnimation(.smooth) {
                self.expandingView.isShow  = status
                self.expandingView.type    = type
                self.expandingView.value   = value
                self.expandingView.browser = browser
            }
        }
    }
    
    func showEmpty() {
        currentView = .home
    }
}
