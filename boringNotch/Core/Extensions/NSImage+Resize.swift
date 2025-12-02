//
//  NSImage+Resize.swift
//  boringNotch
//
//  Created by Eliomar Alejandro Rodriguez Ferrer on 02/12/25.
//

import AppKit

extension NSImage {
    func resized(to targetSize: NSSize) -> NSImage? {
        let frame = NSRect(
            x: 0,
            y: 0,
            width: targetSize.width,
            height: targetSize.height
        )
        
        guard let representation = self.bestRepresentation(
            for: frame,
            context: nil,
            hints: nil
            
        ) else { return nil }
        
        let image = NSImage(size: targetSize, flipped: false) { (dstRect) -> Bool in
            representation.draw(in: dstRect)
            return true
        }
        
        return image
    }
}
