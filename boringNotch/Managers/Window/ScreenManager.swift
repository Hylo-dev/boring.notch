//
//  ScreenManager.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 02/08/24.
//  Editied by Eliomar Rodriguez on 01/12/25.
//

import AppKit
import Combine

class ScreenManager: ObservableObject {
    static let shared = ScreenManager()
    
    @Published var currentScreens: [NSScreen] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        self.updateScreens()
        
        // Ascolta i cambiamenti dei monitor
        NotificationCenter.default.publisher(
            for: NSApplication.didChangeScreenParametersNotification
        )
        .sink { [weak self] _ in self?.updateScreens() }
        .store(in: &cancellables)
    }
    
    private func updateScreens() {
        Task { self.currentScreens = NSScreen.screens }
    }
    
    func screen(for uuid: String) -> NSScreen? {
        currentScreens.first { $0.displayUUID == uuid }
    }
}
