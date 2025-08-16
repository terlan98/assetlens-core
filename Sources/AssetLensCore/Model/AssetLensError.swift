//
//  AssetLensError.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

enum AssetLensError: LocalizedError {
    case cannotReadDirectory(String)
    case invalidImage(String)
    
    var errorDescription: String? {
        switch self {
        case .cannotReadDirectory(let path):
            return "Cannot read directory: \(path)"
        case .invalidImage(let path):
            return "Cannot process image: \(path)"
        }
    }
}
