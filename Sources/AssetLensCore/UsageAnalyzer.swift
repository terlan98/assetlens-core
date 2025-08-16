//
//  UsageAnalyzer.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

public class UsageAnalyzer { // TODO: make async
    public init() {}
    
    public func findUnusedAssets(assets: [ImageAsset], in projectURL: URL, verbosity: VerbosityLevel) -> Set<ImageAsset> {
        guard !assets.isEmpty else { return [] }
        
        if verbosity >= .verbose {
            print("Checking usage of \(assets.count) assets...")
        }
        
        let assets = Set(assets)
        let projectPath = projectURL.path
        
        let escapedNames = assets.map { NSRegularExpression.escapedPattern(for: $0.displayName) }
        let pattern = escapedNames.joined(separator: "|")
        
        if verbosity == .debug {
            print("Searching for \(assets.count) asset names in project files...")
            print("Search pattern length: \(pattern.count) characters")
        }
        
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
                    -rhoI -E '\(pattern)' '\(projectPath)' | sort -u
                    """
        
        let result = execute(command)
        
        // Parse the output to get used asset names
        var usedNames: [String] = []
        
        switch result {
        case .success(let commandResult):
            usedNames = commandResult.output
                .split(separator: "\n")
                .map { String($0) }
                .filter { !$0.isEmpty }
        case .failure(let error):
            if verbosity >= .debug {
                print("Error during shell command execution: \(error)")
            }
        }
        
        let unusedAssets = assets.filter { !usedNames.contains($0.displayName) }
        
        return unusedAssets
    }
    
    @discardableResult
    private func execute(_ command: String) -> Result<CommandResult, Error> {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = Pipe()  // discard stderr
        task.arguments = ["-c", command]
        task.launchPath = "/bin/bash"
        task.standardInput = nil
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            
            return .success(.init(output: output, exitCode: task.terminationStatus))
        } catch {
            return .failure(error)
        }
    }
}

struct CommandResult {
    var output: String
    var exitCode: Int32
}
