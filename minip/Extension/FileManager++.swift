//
//  FileManager++.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Foundation

public extension FileManager {
    func createTempDirectory() throws -> String {
        let tempDirectory = (NSTemporaryDirectory() as NSString).appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(atPath: tempDirectory,
                                                withIntermediateDirectories: true,
                                                attributes: nil)
        return tempDirectory
    }
    
    static func isImage(url: URL?) -> Bool {
        guard let url = url else {
            return false
        }
        let ext = url.pathExtension
        return ext == "jpg" || ext == "jpeg" || ext == "png"
    }
}
