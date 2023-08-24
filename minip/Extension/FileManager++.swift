//
//  FileManager++.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Foundation

public extension FileManager {
    static func isImage(url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        let ext = url.pathExtension.lowercased()
        return ext == "jpg" || ext == "jpeg" || ext == "png"
    }
}
