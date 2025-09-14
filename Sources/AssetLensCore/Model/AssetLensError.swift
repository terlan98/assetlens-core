//
//  AssetLensError.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 09.08.25.
//

import Foundation

enum AssetLensError: LocalizedError {
    case cannotReadDirectory(String)
    
    var errorDescription: String? {
        switch self {
        case .cannotReadDirectory(let path):
            return "Cannot read directory: \(path)"
        }
    }
}
