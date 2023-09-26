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

    func deletingSuffix(_ suffix: String) -> String {
        guard self.hasSuffix(suffix) else { return self }
        return String(self.dropLast(suffix.count))
    }

    func deletingPrefixSuffix(_ s: String) -> String {
        return self.deletingPrefix(s).deletingSuffix(s)
    }
}
