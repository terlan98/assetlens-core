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
    
    public func scanDirectory(at url: URL, minSizeKB: Int) async throws -> [ImageAsset] {
        try await withCheckedThrowingContinuation { continuation in
            Task.detached {
                do {
                    let assets = try self.performScan(at: url, minSizeKB: minSizeKB)
                    continuation.resume(returning: assets)
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    private func performScan(at url: URL, minSizeKB: Int) throws -> [ImageAsset] {
        var assets: [ImageAsset] = []
        var imagesetSizes: [String: Int] = [:]
        let fileManager = FileManager.default
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            throw AssetLensError.cannotReadDirectory(url.path)
        }
        
        for case let fileURL as URL in enumerator {
            // Only process image files inside .imageset directories
            guard fileURL.path.contains(".imageset/"),
                  supportedExtensions.contains(fileURL.pathExtension.lowercased()) else {
                continue
            }
            
            // Check file size
            guard let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize,
                  fileSize >= minSizeKB * 1024 else {
                continue
            }
            
            // Get imageset directory size
            let pathComponents = fileURL.pathComponents
            if let imagesetIndex = pathComponents.firstIndex(where: { $0.hasSuffix(".imageset") }) {
                let imagesetPath = pathComponents[0...imagesetIndex].joined(separator: "/")
                let directorySize: Int
                
                guard imagesetSizes[imagesetPath] == nil else {
                    continue // Cache hit; Skip already processed set
                }
                
                // Cache miss
                let imagesetURL = URL(filePath: imagesetPath)
                directorySize = calculateDirectorySize(at: imagesetURL)
                imagesetSizes[imagesetPath] = directorySize
                
                let asset = ImageAsset(url: fileURL, imageSetSize: directorySize)
                assets.append(asset)
            }
        }
        
        return assets
    }
    
    private func calculateDirectorySize(at url: URL) -> Int {
        let fileManager = FileManager.default
        var totalSize = 0
        
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey, .isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return 0
        }
        
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += fileSize
            }
        }
        
        return totalSize
    }
}
