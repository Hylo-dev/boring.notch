//
//  BoringHeader.swift
//  boringNotch
//
//  Created by Harsh Vardhan  Goswami  on 04/08/24.
//

import Defaults
import SwiftUI
import SegmentedFlowPicker

struct BoringHeaderView: View {
    
    @EnvironmentObject
    var viewModel: BoringViewModel
    
    @ObservedObject
    var batteryModel = BatteryStatusViewModel.shared
    
    @ObservedObject
    var coordinator = BoringViewCoordinator.shared
    
    @StateObject
    var tvm = ShelfStateViewModel.shared
    
    // MARK: - Layout Logic
    
    private var isNotchClosed: Bool { viewModel.notchState == .closed }
    
    private var contentOpacity: Double { isNotchClosed ? 0 : 1 }
    private var contentBlur: CGFloat { isNotchClosed ? 20 : 0 }
    
    private var shouldShowHUD: Bool {
        isHUDType(coordinator.sneakPeek.type) &&
        coordinator.sneakPeek.isShow &&
        Defaults[.showOpenNotchHUD]
    }
    
    // MARK: - Body
    
    var body: some View {
        HStack(spacing: 0) {
            
            // 1. LEFT: Shelf / Tabs
            leftContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .opacity(contentOpacity)
                .blur(radius: contentBlur)
                .zIndex(2)
            
            // 2. CENTER: Hardware Notch Mask
            if viewModel.notchState == .open {
                centerNotch
            }
            
            // 3. RIGHT: Controls & Battery
            rightContent
                .font(.system(.headline, design: .rounded))
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(contentOpacity)
                .blur(radius: contentBlur)
                .zIndex(2)
        }
        .padding(.top, 5)
        .foregroundColor(.gray)
        .environmentObject(viewModel)
    }
    
    // MARK: - Subviews
    
    @ViewBuilder
    private var leftContent: some View {
        if (!tvm.isEmpty || coordinator.alwaysShowTabs) && Defaults[.boringShelf] {
            SegmentedFlowPicker(
                selectedSection: $coordinator.currentView
                
            ) { section in
                Image(systemName: section.rawValue)
            }
            .backgroundColor(.clear)
            .buttonFocusedColor(.effectiveAccent)
            
        } else { EmptyView() }
    }
    
    private var centerNotch: some View {
        let topSafeArea = NSScreen.with(
            uuid: coordinator.selectedScreenUUID
        )?.safeAreaInsets.top ?? 0
        
        return Rectangle()
            .fill(topSafeArea > 0 ? .black : .clear)
            .frame(width: viewModel.closedNotchSize.width)
            .mask { NotchShape() }
    }
    
    @ViewBuilder
    private var rightContent: some View {
        HStack(spacing: 4) {
            if viewModel.notchState == .open {
                
                if shouldShowHUD {
                    // HUD View
                    OpenNotchHUD(
                        type : self.$coordinator.sneakPeek.type,
                        value: self.$coordinator.sneakPeek.value,
                        icon : self.$coordinator.sneakPeek.icon
                    )
                    .transition(.scale(scale: 0.8).combined(with: .opacity))
                    
                } else {
                    // Standard Controls
                    standardControls
                }
            }
        }
    }
    
    @ViewBuilder
    private var standardControls: some View {
        // Camera Mirror Button
        if Defaults[.showMirror] {
            HeaderCircleButton(icon: "web.camera") {
                viewModel.toggleCameraPreview()
            }
        }
        
        // Settings Button
        if Defaults[.settingsIconInNotch] {
            HeaderCircleButton(icon: "gear") {
                SettingsWindowController.shared.showWindow()
            }
        }
        
        // Battery Indicator
        if Defaults[.showBatteryIndicator] {
            BoringBatteryView(
                batteryWidth: 30,
                isCharging: batteryModel.isCharging,
                isInLowPowerMode: batteryModel.isInLowPowerMode,
                isPluggedIn: batteryModel.isPluggedIn,
                levelBattery: batteryModel.levelBattery,
                maxCapacity: batteryModel.maxCapacity,
                timeToFullCharge: batteryModel.timeToFullCharge,
                isForNotification: false
            )
        }
    }
    
    // MARK: - Helpers
    
    private func isHUDType(_ type: SneakContentType) -> Bool {
        switch type {
            case .volume, .brightness, .backlight, .mic:
                return true
            
            default:
                return false
            
        }
    }
}

// MARK: - Reusable Components

/// Un componente riutilizzabile per i bottoni circolari nell'header (Camera, Settings, etc.)
private struct HeaderCircleButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Capsule()
                .fill(.black)
                .frame(width: 30, height: 30)
                .overlay {
                    Image(systemName: icon)
                        .foregroundColor(.white)
                        .padding()
                        .imageScale(.medium)
                }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    BoringHeaderView()
        .environmentObject(BoringViewModel())
        .frame(width: 800, height: 100)
        .background(Color.gray.opacity(0.2))
}
