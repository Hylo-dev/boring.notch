//
//  NotchPillView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI
import Defaults

struct NotchContentRouter: View {
    @EnvironmentObject
    private var viewModel: BoringViewModel
    
    @ObservedObject
    private var coordinator = BoringViewCoordinator.shared
    
    @Binding
    var isHovering: Bool
    
    @Binding
    var gestureProgress: CGFloat
    
    var body: some View {
        switch viewModel.currentContentState {
            
            case .hello:
                HelloAnimationView()
                
            case .battery:
                BatteryStatusView()
                
            case .inlineHUD:
                InlineHUDView(
                    isHovering: self.$isHovering,
                    gestureProgress: self.$gestureProgress
                )
                
            case .music:
                MusicLiveActivityView()
                
            case .boringFace:
                BoringFaceView()
                
            case .open:
                BoringHeaderView()
                    .frame(height: max(24, viewModel.effectiveClosedNotchHeight))
                
            case .empty:
                Rectangle()
                .fill(.clear)
                .frame(width: viewModel.closedNotchSize.width - 20, height: viewModel.effectiveClosedNotchHeight)
        }
    }
}
