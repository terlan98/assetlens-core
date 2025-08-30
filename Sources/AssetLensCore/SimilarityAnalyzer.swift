//
//  SimilarityAnalyzer.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation
import Vision
import AppKit

public class SimilarityAnalyzer {
    public typealias ProgressCallback = (Double) -> Void
    
    let threshold: Float
    private var featurePrintCache: [URL: VNFeaturePrintObservation] = [:]
    
    public init(threshold: Float) {
        self.threshold = threshold
    }
    
    public func findSimilarGroups(in assets: [ImageAsset], verbosity: VerbosityLevel, progressCallback: ProgressCallback? = nil) throws -> [SimilarityGroup] {
        var groups: [SimilarityGroup] = []
        var processedAssets = Set<URL>()
        
        // Generate all feature prints first
        if verbosity >= .verbose {
            print("Generating feature prints for \(assets.count) assets...")
        }
        
        // Pre-generate all feature prints and filter valid assets
        var validAssets: [ImageAsset] = []
        for (index, asset) in assets.enumerated() {
            if verbosity >= .verbose && index % 10 == 0 {
                print("Processing \(index)/\(assets.count) assets...")
            }
            
            do {
                if try getFeaturePrint(for: asset) != nil {
                    validAssets.append(asset)
                } else {
                    print("⚠️ Could not generate feature print for: \(asset.displayName)")
                }
            } catch {
                print("⚠️ Could not generate feature print for: \(asset.displayName): \(error)")
            }
        }
        
        if verbosity >= .verbose {
            print("Analyzing similarities for \(validAssets.count) valid assets...")
        }
        
        if verbosity == .debug {
            print("\n📊 Distance Matrix (lower = more similar):")
            print("Threshold: \(threshold)")
            print("---")
        }
        
        // Find similar groups
        for (index, asset) in validAssets.enumerated() {
            defer {
                if let progressCallback {
                    progressCallback(Double(processedAssets.count) / Double(validAssets.count))
                }
            }
            
            // Skip if already part of a group
            guard !processedAssets.contains(asset.url) else { continue }
            
            guard let print1 = try getFeaturePrint(for: asset) else { continue }
            
            var similarAssets: [(ImageAsset, Float)] = []
            
            // Compare with remaining unprocessed assets
            for otherAsset in validAssets.dropFirst(index + 1) {
                guard !processedAssets.contains(otherAsset.url),
                      let print2 = try getFeaturePrint(for: otherAsset) else { continue }
                
                // Skip if they're from the same imageset (e.g., @1x, @2x, @3x versions)
                if asset.isInSameImageset(as: otherAsset) {
                    continue
                }
                
                var distance: Float = 0
                try print1.computeDistance(&distance, to: print2)
                
                if verbosity == .debug {
                    print("Distance between '\(asset.displayName)' and '\(otherAsset.displayName)': \(String(format: "%.2f", distance))")
                }
                
                if distance <= threshold {
                    similarAssets.append((otherAsset, distance))
                }
            }
            
            processedAssets.insert(asset.url)
            
            // Only create a group if we found similar assets
            if !similarAssets.isEmpty {
                // Mark all similar assets as processed
                for (similarAsset, _) in similarAssets {
                    processedAssets.insert(similarAsset.url)
                }
                
                let group = SimilarityGroup(
                    primary: asset,
                    similar: similarAssets.sorted { $0.1 < $1.1 }
                )
                groups.append(group)
                
                if verbosity == .debug {
                    print("✅ Created group with \(similarAssets.count + 1) assets")
                }
            } else if verbosity == .debug {
                print("ℹ️ No similar assets found for '\(asset.displayName)'")
            }
        }
        
        if verbosity == .debug {
            print("---")
            print("Total groups formed: \(groups.count)")
            print("Total assets processed: \(processedAssets.count)")
            print("Assets not in any group: \(validAssets.count - groups.reduce(0) { $0 + $1.similar.count + 1 })")
        }
        
        return groups
    }
    
    private func getFeaturePrint(for asset: ImageAsset) throws -> VNFeaturePrintObservation? {
        if let cached = featurePrintCache[asset.url] {
            return cached
        }
        
        guard let image = NSImage(contentsOf: asset.url),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }
        
        let request = VNGenerateImageFeaturePrintRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        try handler.perform([request])
        
        guard let observation = request.results?.first as? VNFeaturePrintObservation else {
            return nil
        }
        
        featurePrintCache[asset.url] = observation
        return observation
    }
}
