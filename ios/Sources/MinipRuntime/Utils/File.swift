//
//  file.swift
//  minip
//
//  Created by ByteDance on 2025/7/6.
//

import Foundation

func fileOrFolderExists(path: String) -> (exists: Bool, isDirector: Bool) {
    let fileManager = FileManager.default
    var isDirectory: ObjCBool = false
    let exists = fileManager.fileExists(atPath: path, isDirectory: &isDirectory)
    return (exists, isDirectory.boolValue)
}
