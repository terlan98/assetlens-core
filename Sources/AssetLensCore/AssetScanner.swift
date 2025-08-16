//
//  AssetScanner.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public struct AssetScanner {
    let supportedExtensions = ["png", "jpg", "jpeg", "pdf", "svg"]
    
    public init() {}
    
    public func scanDirectory(at url: URL, minSizeKB: Int) throws -> [ImageAsset] {
        var assets: [ImageAsset] = []
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AssetLensError.cannotReadDirectory(url.path)
        }
        
        for case let fileURL as URL in enumerator {
            // Only process files inside .imageset directories
            guard fileURL.path.contains(".imageset/") else {
                continue
            }
            
            // Skip non-image files
            guard supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }
            
            // Check file size
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
               fileSize < minSizeKB * 1024 {
                continue
            }
            
            let asset = ImageAsset(url: fileURL)
            
            // Check if we already have an asset from this imageset
            let alreadyHasAssetFromSameImageset = assets.contains {  $0.relativePath == asset.relativePath }
            
            if !alreadyHasAssetFromSameImageset {
                assets.append(asset)
            }
        }
        
        return assets
    }
}
