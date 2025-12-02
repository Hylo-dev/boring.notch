//
//  LayoutConfig.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 01/12/25.
//

import Foundation

enum LayoutConfig {
    static let downloadSneakSize = CGSize(width: 65, height: 1)
    static let batterySneakSize = CGSize(width: 160, height: 1)
    static let shadowPadding: CGFloat = 20
    static let openNotchSize = CGSize(width: 640, height: 190)
    
    static var windowSize: CGSize {
        CGSize(width: openNotchSize.width, height: openNotchSize.height + shadowPadding)
    }
    
    struct CornerRadius {
        static let opened = (top: 19.0, bottom: 24.0)
        static let closed = (top: 6.0, bottom: 14.0)
    }
}
