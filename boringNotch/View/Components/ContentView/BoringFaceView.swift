//
//  BoringFaceView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI

struct BoringFaceView: View {
    @EnvironmentObject var viewModel: BoringViewModel
    
    var body: some View {
        HStack {
            HStack {
                Rectangle().fill(.clear)
                    .frame(width: max(0, viewModel.effectiveClosedNotchHeight - 12), height: max(0, viewModel.effectiveClosedNotchHeight - 12))
                Rectangle().fill(.black)
                    .frame(width: viewModel.closedNotchSize.width - 20)
                MinimalFaceFeatures()
            }
        }.frame(height: viewModel.effectiveClosedNotchHeight)
    }
}
