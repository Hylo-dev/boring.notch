//
//  NSScreen+UUID.swift
//  boringNotch
//
//  Created by Alexander on 2025-11-21.
//

import AppKit
import CoreGraphics

// MARK: - Screen UUID Extension
extension NSScreen {
    
    /// Ritorna un UUID persistente per questo display.
    /// Usa CoreGraphics per ottenere un identificativo stabile anche tra riavvii.
    var displayUUID: String? {
        guard let number = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return nil
        }
        
        let displayID = CGDirectDisplayID(number.uint32Value)
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID) else {
            return nil
        }
        
        // takeRetainedValue() gestisce la memoria di CoreFoundation
        return CFUUIDCreateString(nil, uuid.takeRetainedValue()) as String
    }
    
    /// Trova uno schermo dato il suo UUID (Cached).
    /// Accetta String? opzionale per semplificare le chiamate.
    @MainActor
    static func with(uuid: String?) -> NSScreen? {
        guard let uuid else { return nil }
        return ScreenUUIDCache.shared.screen(for: uuid)
    }
}

// MARK: - Screen Cache Manager
/// Cache singleton per evitare lookup costosi ripetuti
@MainActor
final class ScreenUUIDCache {
    static let shared = ScreenUUIDCache()
    
    private var cache: [String: NSScreen] = [:]
    private var observer: NSObjectProtocol?
    
    private init() {
        rebuildCache()
        
        // Osserva i cambiamenti dei monitor (es. stacchi/attacchi un cavo HDMI)
        observer = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.rebuildCache()
        }
    }
    
    deinit {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func rebuildCache() {
        cache = NSScreen.screens.reduce(into: [String: NSScreen]()) { dict, screen in
            if let uuid = screen.displayUUID {
                dict[uuid] = screen
            }
        }
    }
    
    func screen(for uuid: String) -> NSScreen? {
        return cache[uuid]
    }
}
