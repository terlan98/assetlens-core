//
//  Int64+FormattedSize.swift
//  AssetLensCore
//
//  Created by Tarlan Ismayilsoy on 23.08.25.
//

import Foundation

public extension Int64 {
    public func formattedAsBytes() -> String {
        self.formatted(.byteCount(style: .file))
    }
}
