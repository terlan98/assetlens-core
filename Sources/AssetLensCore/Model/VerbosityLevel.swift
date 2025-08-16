//
//  VerbosityLevel.swift
//  AssetLens
//
//  Created by Tarlan Ismayilsoy on 13.08.25.
//

import Foundation

public enum VerbosityLevel: String, CaseIterable, Comparable {
    case normal
    case verbose
    case debug
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        let order = Self.allCases
        return order.firstIndex(of: lhs)! < order.firstIndex(of: rhs)!
    }
}
