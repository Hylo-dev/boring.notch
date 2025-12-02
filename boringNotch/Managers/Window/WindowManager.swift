//
//  WindowManager.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 02/08/24.
//  Editied by Eliomar Rodriguez on 01/12/25.
//

import AppKit
import SwiftUI
import Combine
import Defaults

@MainActor
class WindowManager: ObservableObject {
    static let shared = WindowManager()
    
    // Stato interno
    private var windows: [String: NSWindow] = [:]      // UUID -> Window
    private var viewModels: [String: BoringViewModel] = [:] // UUID -> ViewModel
    private var dragDetectors: [String: DragDetector] = [:] // UUID -> Detector
    
    private var cancellables = Set<AnyCancellable>()
    private var isScreenLocked: Bool = false
    
    private init() {
        setupObservers()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Monitor
        ScreenManager.shared.$currentScreens
            .sink { [weak self] _ in self?.refreshWindows() }
            .store(in: &cancellables)
        
        // Preferenze
        Defaults.publisher(.showOnAllDisplays)
            .sink { [weak self] _ in self?.refreshWindows() }
            .store(in: &cancellables)
        
        Defaults.publisher(.expandedDragDetection)
            .sink { [weak self] _ in self?.refreshDragDetectors() }
            .store(in: &cancellables)
        
        Defaults.publisher(.notchHeight) // Ascolta cambio altezza notch
            .sink { [weak self] _ in self?.repositionAllWindows() }
            .store(in: &cancellables)

        // Lock Screen
        DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.screenIsLocked"), object: nil, queue: .main) { [weak self] _ in
            
            Task { @MainActor in
                self?.handleLockState(locked: true)
            }
        }
        
        DistributedNotificationCenter.default().addObserver(forName: .init("com.apple.screenIsUnlocked"), object: nil, queue: .main) { [weak self] _ in
            
            Task { @MainActor in
                self?.handleLockState(locked: false)
            }
            
        }
    }
    
    // MARK: - Window Management
    
    func refreshWindows() {
        let screens = ScreenManager.shared.currentScreens
        let showOnAll = Defaults[.showOnAllDisplays]
        let activeUUIDs = Set(screens.compactMap { $0.displayUUID })
        
        // 1. Rimuovi finestre obsolete
        for (uuid, window) in windows {
            // Se lo schermo non esiste più, o se non dobbiamo mostrare su tutti e questo non è il main
            let isMain = (uuid == getMainScreenUUID())
            let shouldKeep = activeUUIDs.contains(uuid) && (showOnAll || isMain)
            
            if !shouldKeep {
                closeWindow(uuid: uuid)
            }
        }
        
        // 2. Crea o aggiorna finestre
        for screen in screens {
            guard let uuid = screen.displayUUID else { continue }
            let isMain = (uuid == getMainScreenUUID())
            
            if showOnAll || isMain {
                if windows[uuid] == nil {
                    createWindow(for: screen, uuid: uuid)
                }
                // Riposiziona sempre per sicurezza
                if let win = windows[uuid] {
                    positionWindow(win, on: screen)
                }
            }
        }
        
        refreshDragDetectors()
    }
    
    private func createWindow(for screen: NSScreen, uuid: String) {
        let vm = BoringViewModel(screenUUID: uuid)
        
        let width = LayoutConfig.windowSize.width
        let height = LayoutConfig.windowSize.height
        let rect = NSRect(x: 0, y: 0, width: width, height: height)
        let styleMask: NSWindow.StyleMask = [.borderless, .nonactivatingPanel, .utilityWindow, .hudWindow]
        
        let window = BoringNotchSkyLightWindow(contentRect: rect, styleMask: styleMask, backing: .buffered, defer: false)
        
        window.contentView = NSHostingView(
            rootView: ContentView().environmentObject(vm)
        )
        window.backgroundColor = .clear
        window.isOpaque = false
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Gestione SkyLight iniziale
        if isScreenLocked {
            window.enableSkyLight()
        } else {
            window.disableSkyLight()
        }
        
        window.orderFrontRegardless()
        
        windows[uuid] = window
        viewModels[uuid] = vm
        NotchSpaceManager.shared.notchSpace.windows.insert(window)
    }
    
    private func closeWindow(uuid: String) {
        if let window = windows[uuid] {
            window.close()
            NotchSpaceManager.shared.notchSpace.windows.remove(window)
        }
        windows.removeValue(forKey: uuid)
        viewModels.removeValue(forKey: uuid)
        dragDetectors[uuid]?.stopMonitoring()
        dragDetectors.removeValue(forKey: uuid)
    }
    
    private func positionWindow(_ window: NSWindow, on screen: NSScreen) {
        let screenFrame = screen.frame
        let x = screenFrame.origin.x + (screenFrame.width / 2) - (window.frame.width / 2)
        let y = screenFrame.origin.y + screenFrame.height - window.frame.height
        window.setFrameOrigin(NSPoint(x: x, y: y))
        window.alphaValue = 1.0
    }
    
    private func repositionAllWindows() {
        for (uuid, window) in windows {
            if let screen = ScreenManager.shared.screen(for: uuid) {
                positionWindow(window, on: screen)
            }
        }
    }
    
    // MARK: - Drag Detection
    
    private func refreshDragDetectors() {
        guard Defaults[.expandedDragDetection] else {
            dragDetectors.values.forEach { $0.stopMonitoring() }
            dragDetectors.removeAll()
            return
        }
        
        for (uuid, _) in windows {
            if dragDetectors[uuid] == nil, let screen = ScreenManager.shared.screen(for: uuid) {
                setupDragDetector(for: screen, uuid: uuid)
            }
        }
    }
    
    private func setupDragDetector(for screen: NSScreen, uuid: String) {
        let screenFrame = screen.frame
        let notchW = LayoutConfig.openNotchSize.width
        let notchH = LayoutConfig.openNotchSize.height
        
        let region = CGRect(
            x: screenFrame.midX - notchW / 2,
            y: screenFrame.maxY - notchH,
            width: notchW,
            height: notchH
        )
        
        let detector = DragDetector(notchRegion: region)
        detector.onDragEntersNotchRegion = { [weak self] in
            Task { @MainActor in
                self?.viewModels[uuid]?.open()
                BoringViewCoordinator.shared.currentView = .shelf
            }
        }
        
        detector.startMonitoring()
        dragDetectors[uuid] = detector
    }
    
    // MARK: - Actions & Helpers
    
    private func handleLockState(locked: Bool) {
        isScreenLocked = locked
        let showOnLock = Defaults[.showOnLockScreen]
        
        windows.values.forEach { window in
            guard let skyWin = window as? BoringNotchSkyLightWindow else { return }
            
            if locked {
                if showOnLock { skyWin.enableSkyLight() }
                else { window.alphaValue = 0 }
            } else {
                // Unlocked
                // Ritardo per evitare flicker
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                     if showOnLock { skyWin.disableSkyLight() }
                     else { window.alphaValue = 1 }
                }
            }
        }
    }
    
    private func getMainScreenUUID() -> String? {
        return NSScreen.main?.displayUUID ?? NSScreen.screens.first?.displayUUID
    }
    
    func closeAll() {
        windows.values.forEach { $0.close() }
        windows.removeAll()
        viewModels.removeAll()
        dragDetectors.values.forEach { $0.stopMonitoring() }
        dragDetectors.removeAll()
    }
    
    // Funzione chiamata dalla Shortcut
    func toggleNotchUnderMouse(mouseLocation: NSPoint) {
        // Cerca lo schermo sotto il mouse
        let screen = ScreenManager.shared.currentScreens.first { $0.frame.contains(mouseLocation) }
        guard let uuid = screen?.displayUUID, let vm = viewModels[uuid] else { return }
        
        if vm.notchState == .closed {
            vm.open()
            // Chiudi automaticamente dopo 3 secondi
            Task {
                try? await Task.sleep(for: .seconds(3))
                await MainActor.run { vm.close() }
            }
        } else {
            vm.close()
        }
    }
}
