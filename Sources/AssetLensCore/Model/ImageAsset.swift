//
//  ImageAsset.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public struct ImageAsset: Identifiable, Sendable {
    public let id = UUID()
    public let url: URL
    public var imageSetSize: Int
    public var isUsed: Bool?
    public var isDeleted: Bool = false
    
    /// Returns the display name for the asset (imageset name if in .xcassets, otherwise filename)
    public var displayName: String {
        return imageSetName ?? url.deletingPathExtension().lastPathComponent
    }
    
    /// Returns the imageset name if this asset is part of an .imageset directory
    public var imageSetName: String? {
        // Check if this file is inside an .imageset directory
        let pathComponents = url.pathComponents
        
        // Find the .imageset component in the path
        if let imagesetIndex = pathComponents.firstIndex(where: { $0.hasSuffix(".imageset") }) {
            // Return the imageset name without the extension
            let imagesetComponent = pathComponents[imagesetIndex]
            return String(imagesetComponent.dropLast(".imageset".count))
        }
        
        return nil
    }
    
    /// Returns a user-friendly relative path including the imageset name
    public var relativePath: String {
        // If it's in an imageset, show the path up to the imageset
        if imageSetName != nil {
            let pathComponents = url.pathComponents
            if let imagesetIndex = pathComponents.firstIndex(where: { $0.hasSuffix(".imageset") }) {
                // Build path up to and including the imageset
                let relevantComponents = pathComponents[0...imagesetIndex]
                
                // Find .xcassets in the path to make it relative from there
                if let xcassetsIndex = relevantComponents.firstIndex(where: { $0.hasSuffix(".xcassets") }) {
                    let fromXcassets = relevantComponents[(xcassetsIndex)...]
                    return fromXcassets.joined(separator: "/")
                }
            }
        }
        
        // Fallback to just the filename
        return url.lastPathComponent
    }
    
    public init(url: URL, isUsed: Bool? = nil, imageSetSize: Int = 0) {
        self.url = url
        self.isUsed = isUsed
        self.imageSetSize = imageSetSize
    }
    
    /// Check if two assets are from the same imageset
    public func isInSameImageSet(as other: ImageAsset) -> Bool {
        return other.imageSetName == imageSetName
    }
}

// Make ImageAsset Hashable for Set operations
extension ImageAsset: Hashable {
    public static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
        lhs.id == rhs.id
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
