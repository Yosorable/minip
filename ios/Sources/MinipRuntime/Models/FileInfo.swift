//
//  FileInfo.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import Foundation

struct FileInfo: Hashable {
    var fileName: String
    var isFolder: Bool
    var url: URL
    var size: String?
    var lastModified: Date?
    var filesCount: Int?

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }

    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        return lhs.url == rhs.url
    }

    func contentEquals(_ other: FileInfo) -> Bool {
        return url == other.url && size == other.size && filesCount == other.filesCount && lastModified == other.lastModified
    }
}
