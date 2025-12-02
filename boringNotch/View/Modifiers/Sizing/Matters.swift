//
//  sizeMatters.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 05/08/24.
//

import Defaults
import Foundation
import SwiftUI

@MainActor
func getScreenFrame(_ screenUUID: String? = nil) -> CGRect? {
    let screen = NSScreen.with(uuid: screenUUID) ?? .main
    return screen?.frame
}

@MainActor
func getClosedNotchSize(screenUUID: String? = nil) -> CGSize {
    // 1. Identifica lo schermo (Fallback su main se non trovato)
    let selectedScreen = NSScreen.with(uuid: screenUUID) ?? NSScreen.main
    
    // Se per qualche motivo assurdo non c'è neanche un main screen (es. mac mini headless), usiamo default
    guard let screen = selectedScreen else {
        return CGSize(width: 185, height: Defaults[.nonNotchHeight])
    }

    // 2. Calcola dimensioni
    let width = calculateNotchWidth(for: screen)
    let height = calculateNotchHeight(for: screen)

    return CGSize(width: width, height: height)
}

// MARK: - Helpers

@MainActor
private func calculateNotchWidth(for screen: NSScreen) -> CGFloat {
    if let topLeft = screen.auxiliaryTopLeftArea?.width,
       let topRight = screen.auxiliaryTopRightArea?.width {
        return screen.frame.width - topLeft - topRight + 4
    }
    return 185
}

@MainActor 
private func calculateNotchHeight(for screen: NSScreen) -> CGFloat {
    let hasNotch = screen.safeAreaInsets.top > 0
    
    if hasNotch {
        switch Defaults[.notchHeightMode] {
            case .matchRealNotchSize:
                return screen.safeAreaInsets.top
            
            case .matchMenuBar:
                return screen.frame.maxY - screen.visibleFrame.maxY
            
            default:
                return Defaults[.notchHeight]
        }
        
    } else {
        if Defaults[.nonNotchHeightMode] == .matchMenuBar {
            return screen.frame.maxY - screen.visibleFrame.maxY
            
        } else { return Defaults[.nonNotchHeight] }
    }
}
