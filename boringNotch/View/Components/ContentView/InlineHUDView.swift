//
//  InlineHUDView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI

struct InlineHUDView: View {
    @ObservedObject
    var coordinator = BoringViewCoordinator.shared
    
    @Binding
    var isHovering: Bool
    
    @Binding
    var gestureProgress: CGFloat
    
    var body: some View {
        
        InlineHUD(
            type: $coordinator.sneakPeek.type,
            value: $coordinator.sneakPeek.value,
            icon: $coordinator.sneakPeek.icon,
            hoverAnimation: $isHovering,
            gestureProgress: $gestureProgress
        )
        .transition(.opacity)
    }
}
