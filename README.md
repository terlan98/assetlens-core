<img src="icon.png" height="50em">

# AssetLensCore

A Swift Package for finding visually similar assets in Xcode projects. 📱✨

## What does it do?

Helps you clean up your Xcode projects by finding and analyzing image assets that might be cluttering your app bundle.

## Key Features

### 🔍 Asset Scanning
Scans your project directories for image assets in `.imageset` folders, supporting common formats:
- PNG, JPG, JPEG
- PDF  
- SVG

### 📊 Usage Analysis
Uses intelligent grep patterns to search through the files to determine which assets are actually being used in your project.

### 🎯 Similarity Detection
Leverages Apple's Vision framework to find visually similar images that might be duplicates or candidates for consolidation.
You can adjust the similarity threshold as you wish. The recommended value is `0.5`

## Quick Usage

```swift
import AssetLensCore

// Scan for large assets
let scanner = AssetScanner()
let assets = try await scanner.scanDirectory(at: projectURL, minSizeKB: 100)

// Find unused assets
let analyzer = UsageAnalyzer()
let unused = await analyzer.findUnusedAssets(assets: assets, in: projectURL, verbosity: .verbose)

// Find similar images
let similarityAnalyzer = SimilarityAnalyzer(threshold: 0.5)
let similarGroups = try await similarityAnalyzer.findSimilarGroups(in: assets)
```

## Perfect For
- Keeping your app lightweight by eliminating duplicates
- Facilitating asset organization for better developer experience

## License
This project is available under the GNU General Public License license.
