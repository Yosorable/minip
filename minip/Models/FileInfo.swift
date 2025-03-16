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
}
