//
//  String++.swift
//  minip
//
//  Created by LZY on 2023/9/23.
//

import Foundation

extension String {
    func deletingPrefix(_ prefix: String) -> String {
        guard self.hasPrefix(prefix) else { return self }
        return String(self.dropFirst(prefix.count))
    }

    /// UTF-8 decode convenience. Previously provided by SwiftLMDB's
    /// `DataConvertible`; kept after dropping that dependency since a few
    /// API helpers rely on `String(data:)` without an explicit encoding.
    init?(data: Data) {
        self.init(data: data, encoding: .utf8)
    }
}
