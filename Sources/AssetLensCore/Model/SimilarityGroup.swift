//
//  SimilarityGroup.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public struct SimilarityGroup {
    public var primary: ImageAsset
    public var similar: [(ImageAsset, Float)]
    
    /// All assets in the group (primary + similar)
    public var allAssets: [ImageAsset] {
        [primary] + similar.map { $0.0 }
    }
    
    public var totalSize: Int64 {
        allAssets.reduce(0) { $0 + $1.fileSize }
    }
    
    public var potentialSavings: Int64 {
        if allAssets.allSatisfy({ $0.isUsed == false }) {
            return totalSize
        } else {
            let smallestAssetSize = allAssets.map { $0.fileSize }.min() ?? 0
            return totalSize - smallestAssetSize
        }
    }
}
