//
//  HelloAnimationView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI

struct HelloAnimationView: View {
    @EnvironmentObject
    var viewModel: BoringViewModel
    
    var body: some View {
        Spacer()
        HelloAnimation(onFinish: { viewModel.closeHello() })
            .frame(width: viewModel.closedNotchSize.width, height: 80)
            .padding(.top, 40)
        Spacer()
    }
}
