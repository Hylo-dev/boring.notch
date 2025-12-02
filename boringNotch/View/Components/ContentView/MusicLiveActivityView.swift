//
//  MusicLiveActivityView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI
import Defaults

struct MusicLiveActivityView: View {
    
    @ObservedObject
    var musicManager = MusicManager.shared
    
    @ObservedObject
    var coordinator = BoringViewCoordinator.shared
    
    @EnvironmentObject
    var viewModel: BoringViewModel
    
    @Default(.useMusicVisualizer)
    var useMusicVisualizer
    
    @Namespace
    var albumArtNamespace
    
    var body: some View {
        HStack {
            Image(nsImage: self.musicManager.albumArt)
                .resizable()
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: MusicPlayerImageSizes.cornerRadiusInset.closed
                    )
                )
                .matchedGeometryEffect(id: "albumArt", in: albumArtNamespace)
                .frame(
                    width: max(0, viewModel.effectiveClosedNotchHeight - 12),
                    height: max(0, viewModel.effectiveClosedNotchHeight - 12)
                )
            
            Rectangle()
                .fill(.black)
                .overlay(
                    HStack(alignment: .top) {
                        if coordinator.expandingView.isShow && coordinator.expandingView.type == .music {
                            
                            MarqueeText(
                                .constant(musicManager.songTitle),
                                font: .headline,
                                textColor: Defaults[.coloredSpectrogram] ? Color(nsColor: musicManager.avgColor) : Color.gray,
                                minDuration: 0.4,
                                frameWidth: 100
                            )
                            .opacity(
                                (coordinator.expandingView.isShow && Defaults[.sneakPeekStyles] == .inline) ? 1 : 0
                            )
                            
                            Spacer(minLength: viewModel.closedNotchSize.width)
                            
                            Text(musicManager.artistName)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .font(.footnote)
                                .foregroundStyle(Defaults[.coloredSpectrogram] ? Color(nsColor: musicManager.avgColor) : Color.gray)
                                .opacity((coordinator.expandingView.isShow && coordinator.expandingView.type == .music && Defaults[.sneakPeekStyles] == .inline) ? 1 : 0)
                        }
                    }
                )
                .frame(width: (coordinator.expandingView.isShow && coordinator.expandingView.type == .music && Defaults[.sneakPeekStyles] == .inline) ? 380 : viewModel.closedNotchSize.width + LayoutConfig.CornerRadius.closed.top)
            
            HStack {
                if useMusicVisualizer {
                    Rectangle()
                        .fill(Defaults[.coloredSpectrogram] ? Color(nsColor: musicManager.avgColor).gradient : Color.gray.gradient)
                        .frame(width: 50, alignment: .center)
                        .matchedGeometryEffect(id: "spectrum", in: albumArtNamespace)
                        .mask { AudioSpectrumView(isPlaying: $musicManager.isPlaying).frame(width: 16, height: 12) }
                    
                } else {
                    LottieAnimationContainer()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .frame(
                width: max(0, viewModel.effectiveClosedNotchHeight - 12),
                height: max(0, viewModel.effectiveClosedNotchHeight - 12)
            )
        }
        .frame(height: viewModel.effectiveClosedNotchHeight)
    }
}
