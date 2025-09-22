//
//  UsageAnalyzer.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public struct UsageAnalyzer {
    public init() {}
    
    public func findUnusedAssets(assets: [ImageAsset], in projectURL: URL, verbosity: VerbosityLevel) async -> Set<ImageAsset> {
        guard !assets.isEmpty else { return [] }
        
        if verbosity >= .verbose {
            print("Checking usage of \(assets.count) assets...")
        }
        
        let assets = Set(assets)
        let projectPath = projectURL.path
        var usedNames: Set<String> = []
        
        let names = assets.map(\.displayName)
        var nameToImageResourceName = imageResourceNames(for: names)
        
        // MARK: - Search by name
        let escapedNames = names.map { NSRegularExpression.escapedPattern(for: prepareStringForNameSearch($0)) }
        let escapedNamesSearchPattern = escapedNames.joined(separator: "|")
        
        if verbosity == .debug {
            print("Searching for \(assets.count) asset names in project files...")
            print("Search pattern length for names: \(escapedNamesSearchPattern.count) characters")
        }
        
        let nameSearchResult = await search(at: projectPath, for: escapedNamesSearchPattern)
        usedNames.formUnion(getNames(from: nameSearchResult))
        
        // MARK: - Search by image resource name
        usedNames.forEach { usedName in // remove already found assets' names for optimizing the search
            nameToImageResourceName.removeValue(forKey: usedName)
        }
        
        let escapedImageResourceNames = Array(nameToImageResourceName.values)
            .compactMap { $0 }
            .map { "(?i)" + NSRegularExpression.escapedPattern(for: $0) } // (?i) for case insensitivity
        let escapedImageResourceNamesSearchPattern = escapedImageResourceNames.joined(separator: "|")
        
        if verbosity == .debug {
            print("Search pattern length for resource names: \(escapedImageResourceNamesSearchPattern.count) characters")
        }
        
        let imageResourceNameSearchResult = await search(at: projectPath, for: escapedImageResourceNamesSearchPattern)
        usedNames.formUnion(getNames(from: imageResourceNameSearchResult))
        
        // MARK: - Final result based on all searches
        let unusedAssets = assets.filter { asset in
            let isNotUsedAsStringLiteral = !usedNames.contains(prepareStringForNameSearch(asset.displayName))
            let isNotUsedAsImageResource = !usedNames.contains { $0.lowercased() == nameToImageResourceName[asset.displayName]?.lowercased() }
            
            return isNotUsedAsStringLiteral && isNotUsedAsImageResource
        }
        
        return unusedAssets
    }
    
    /// Maps the given array of asset names to possible image resource names
    private func imageResourceNames(for assetNames: [String]) -> [String: String] {
        let allowedCharacters = CharacterSet.alphanumerics
        var assetNameToImageResourceName: [String: String] = [:]
        
        assetNames.forEach { name in
            let transformedName = name.unicodeScalars
                .compactMap { allowedCharacters.contains($0) ? String($0) : nil }
                .joined()
            
            if !transformedName.isEmpty && transformedName != name {
                assetNameToImageResourceName[name] = transformedName
            }
        }
        
        return assetNameToImageResourceName
    }
    
    private func search(at path: String, for pattern: String) async -> Result<CommandResult, Error> {
        // -r: recursive
        // -h: no filenames
        // -o: only matches
        // -I: ignore binary files
        // -E: extended regex (for | operator)
        let command = """
                    grep --include="*.swift" --include="*.m" --include="*.h" \
                    --include="*.storyboard" --include="*.xib" --include="*.plist" \
                    --exclude-dir=".git" --exclude-dir="Build" \
                    --exclude-dir="Pods" --exclude-dir="Carthage" \
                    -rhoI -E '\(pattern)' '\(path)' | sort -u
                    """
        
        return await execute(command)
    }
    
    private func execute(_ command: String) async -> Result<CommandResult, Error> {
        return await withCheckedContinuation { continuation in
            Task.detached {
                let process = Process()
                let pipe = Pipe()
                
                process.standardOutput = pipe
                process.standardError = Pipe()  // discard stderr
                process.arguments = ["-c", command]
                process.launchPath = "/bin/bash"
                process.standardInput = nil
                
                do {
                    try process.run()
                    
                    process.waitUntilExit()
                    
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = String(data: data, encoding: .utf8)?
                        .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                    
                    continuation.resume(returning: .success(.init(output: output, exitCode: process.terminationStatus)))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    private func prepareStringForNameSearch(_ string: String) -> String {
        "\"" + string + "\""
    }
    
    private func getNames(from result: Result<CommandResult, Error>) -> Set<String> {
        switch result {
        case .success(let commandResult):
            return Set(
                commandResult.output
                    .split(separator: "\n")
                    .map { String($0) }
                    .filter { !$0.isEmpty }
            )
        case .failure(let error):
            print("Error during shell command execution: \(error)")
            return []
        }
    }
}

struct CommandResult {
    var output: String
    var exitCode: Int32
}
