//
//  OpenNotchBodyView.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import SwiftUI
import AppKit

struct OpenNotchBodyView: View {
    
    @ObservedObject
    var coordinator = BoringViewCoordinator.shared
    
    @EnvironmentObject
    var viewModel: BoringViewModel
    
    @Namespace
    var albumArtNamespace
    
    var gestureProgress: CGFloat
    
    private var currentIndex: Int {
        switch coordinator.currentView {
            case .home    : return 0
            case .calendar: return 1
            case .shelf   : return 2
        }
    }
    
    private func changeTab(to index: Int) {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            switch index {
                case 0: coordinator.currentView = .home
                case 1: coordinator.currentView = .calendar
                case 2: coordinator.currentView = .shelf
                
                default: break
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                NotchHomeView(albumArtNamespace: albumArtNamespace)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                Rectangle().fill(Color.clear)
                    .overlay(Text("Calendar").foregroundColor(.gray))
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                ShelfView()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
            }
            .offset(x: -CGFloat(currentIndex) * geometry.size.width)
        }
        .transition(
            .scale(scale: 0.8, anchor: .top)
            .combined(with: .opacity).animation(.smooth(duration: 0.35)))
        .zIndex(1)
        .allowsHitTesting(viewModel.notchState == .open)
        .opacity(
            gestureProgress != 0 ? 1.0 - min(abs(gestureProgress) * 0.1, 0.3) : 1.0
        )
        .background {
            let cases = NotchViews.allCases.count - 1
            
            TrackpadSwipeView(
                onSwipeLeft: {
                    if currentIndex >= cases {
                        changeTab(to: 0)
                         
                    } else { changeTab(to: currentIndex + 1) }
                },
                
                onSwipeRight: {
                    if currentIndex <= 0 {
                        changeTab(to: cases)
                        
                    } else { changeTab(to: currentIndex - 1) }
                }
            )
            
        }
    }
}

private struct TrackpadSwipeView: NSViewRepresentable {
    var onSwipeLeft: () -> Void
    var onSwipeRight: () -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = .clear
        context.coordinator.setupMonitor()
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwipeLeft: onSwipeLeft, onSwipeRight: onSwipeRight)
    }

    class Coordinator {
        var onSwipeLeft: () -> Void
        var onSwipeRight: () -> Void
        var monitor: Any?
        
        // Accumulatore di movimento
        var scrollAccumulator: CGFloat = 0
        // Blocco per evitare doppi scatti durante lo stesso gesto
        var hasTriggeredAction: Bool = false

        init(onSwipeLeft: @escaping () -> Void, onSwipeRight: @escaping () -> Void) {
            self.onSwipeLeft = onSwipeLeft
            self.onSwipeRight = onSwipeRight
        }

        func setupMonitor() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                self?.handleEvent(event)
                return event
            }
        }
        
        deinit {
            if let monitor = monitor {
                NSEvent.removeMonitor(monitor)
            }
        }

        private func handleEvent(_ event: NSEvent) {
            // 1. Ignoriamo la fase di inerzia (quando lasci le dita e scorre da solo)
            guard event.momentumPhase == [] else {
                // Resettiamo quando finisce l'inerzia per essere pronti al prossimo gesto
                if event.momentumPhase == .ended {
                    resetState()
                }
                return
            }

            // 2. Se il gesto è finito o cancellato, resettiamo tutto
            if event.phase == .ended || event.phase == .cancelled {
                resetState()
                return
            }
            
            // 3. Se abbiamo già scattato l'azione per questo movimento delle dita, ignoriamo finché non alza le dita
            guard !hasTriggeredAction else { return }

            // 4. Accumuliamo il delta orizzontale
            // scrollingDeltaX è più preciso di deltaX per i trackpad
            scrollAccumulator += event.scrollingDeltaX

            // 5. Soglia di sensibilità (puoi cambiare 30.0 con un numero più basso se lo vuoi più sensibile)
            let threshold: CGFloat = 30.0

            if scrollAccumulator > threshold {
                // Swipe verso Destra (contenuto va a destra)
                DispatchQueue.main.async { self.onSwipeRight() }
                hasTriggeredAction = true
            } else if scrollAccumulator < -threshold {
                // Swipe verso Sinistra
                DispatchQueue.main.async { self.onSwipeLeft() }
                hasTriggeredAction = true
            }
        }
        
        private func resetState() {
            scrollAccumulator = 0
            hasTriggeredAction = false
        }
    }
}
