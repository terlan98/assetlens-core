//
//  SimilarityGroup.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public struct SimilarityGroup: Sendable, Identifiable {
    public var primary: ImageAsset
    public var similar: [(ImageAsset, Float)]
    
    public var id: UUID {
        primary.id
    }
    
    public init(primary: ImageAsset, similar: [(ImageAsset, Float)]) {
        self.primary = primary
        self.similar = similar
    }
    
    /// All assets in the group (primary + similar)
    public var allAssets: [ImageAsset] {
        [primary] + similar.map { $0.0 }
    }
    
    public var unusedAssets: [ImageAsset] {
        allAssets.filter { $0.isUsed == false }
    }
    
    public var totalSize: Int {
        allAssets.reduce(0) { $0 + $1.imageSetSize }
    }
    
    public var potentialSavings: Int {
        if allAssets.allSatisfy({ $0.isUsed == false }) {
            return totalSize
        } else {
            let smallestAssetSize = allAssets.map { $0.imageSetSize }.min() ?? 0
            return totalSize - smallestAssetSize
        }
    }
    
    public var allUnused: Bool {
        allAssets.allSatisfy({ $0.isUsed == false })
    }
}

extension SimilarityGroup: Hashable {
    public static func == (lhs: SimilarityGroup, rhs: SimilarityGroup) -> Bool {
        lhs.primary == rhs.primary
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(primary)
    }
}
