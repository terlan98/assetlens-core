//
//  NSImage+Rasterization.swift
//  AssetLensCore
//
//  Created by Tarlan Ismayilsoy on 05.10.25.
//

import AppKit

extension NSImage {
    func rasterizedCGImageWithOutline(size: NSSize) -> CGImage? {
        let pixelWidth = Int(size.width)
        let pixelHeight = Int(size.height)
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }
        
        guard let context = CGContext(
            data: nil,
            width: pixelWidth,
            height: pixelHeight,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }
        
        context.interpolationQuality = .high
        
        // Medium gray background to replace transparent region
        context.setFillColor(CGColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: pixelWidth, height: pixelHeight))
        
        NSGraphicsContext.saveGraphicsState()
        defer { NSGraphicsContext.restoreGraphicsState() }
        
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
        
        let drawRect = NSRect(x: 0, y: 0, width: CGFloat(pixelWidth), height: CGFloat(pixelHeight))
        
        // Draw outline/shadow effect first (for light colored content)
        context.setShadow(offset: CGSize(width: 0, height: 0), blur: 2.0,
                         color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.5))
        self.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        // Draw the main image
        context.setShadow(offset: .zero, blur: 0)
        self.draw(in: drawRect, from: .zero, operation: .sourceOver, fraction: 1.0)
        
        return context.makeImage()
    }
    
    var hasTransparency: Bool {
        return !representations.contains { $0.isOpaque }
    }
}
