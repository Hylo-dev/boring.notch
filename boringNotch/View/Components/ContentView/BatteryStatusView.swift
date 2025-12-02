//
//  BatteryStatusView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI

struct BatteryStatusView: View {
    
    @ObservedObject
    var batteryModel = BatteryStatusViewModel.shared
    
    @EnvironmentObject
    var viewModel: BoringViewModel
    
    var body: some View {
        HStack(spacing: 0) {
            HStack {
                Text(batteryModel.statusText)
                    .font(.subheadline)
                    .foregroundStyle(.white)
            }
            
            Rectangle().fill(.black)
                .frame(width: viewModel.closedNotchSize.width + 10)
            
            HStack {
                BoringBatteryView(
                    batteryWidth: 30,
                    isCharging: batteryModel.isCharging,
                    isInLowPowerMode: batteryModel.isInLowPowerMode,
                    isPluggedIn: batteryModel.isPluggedIn,
                    levelBattery: batteryModel.levelBattery,
                    isForNotification: true
                )
            }
            .frame(width: 76, alignment: .trailing)
            
        }
        .frame(height: viewModel.effectiveClosedNotchHeight, alignment: .center)
    }
}
