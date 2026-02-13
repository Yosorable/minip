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

func formatFileSize(_ bytes: UInt64) -> String {
    let units = ["B", "KB", "MB", "GB", "TB"]
    var size = Double(bytes)
    var unitIndex = 0

    while size >= 1024 && unitIndex < units.count - 1 {
        size /= 1024
        unitIndex += 1
    }

    return String(format: "%.2f%@", size, units[unitIndex])
}

func cleanTrashAsync(
    onComplete: (() -> Void)? = nil,
    onError: ((Error) -> Void)? = nil
) {
    DispatchQueue.global().async {
        let trashURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        )[0].appending(component: ".Trash", directoryHint: .isDirectory)

        do {
            let fileURLs = try FileManager.default.contentsOfDirectory(
                at: trashURL,
                includingPropertiesForKeys: nil
            )
            for fileURL in fileURLs {
                try FileManager.default.removeItem(at: fileURL)
            }
            DispatchQueue.main.async {
                onComplete?()
            }
        } catch {
            DispatchQueue.main.async {
                onError?(error)
            }
        }
    }
}

func listFilesAndFolders(in directory: URL) throws -> (
    folders: [FileInfo], files: [FileInfo]
) {
    var folders = [FileInfo]()
    var files = [FileInfo]()

    let fileManager = FileManager.default
    let metaDataKeys: Set<URLResourceKey> = [
        .fileSizeKey, .isDirectoryKey, .contentModificationDateKey,
        .attributeModificationDateKey,
    ]
    let contents = try fileManager.contentsOfDirectory(
        at: directory,
        includingPropertiesForKeys: metaDataKeys.map { $0 }
    )
    for ele in contents {
        let resource = try ele.resourceValues(forKeys: metaDataKeys)
        if let isDir = resource.isDirectory {
            let url = ele.standardizedFileURL
            var lastModified =
                resource.contentModificationDate
                ?? resource.attributeModificationDate
            if let date1 = resource.contentModificationDate,
                let date2 = resource.attributeModificationDate
            {
                if date2 > date1 {
                    lastModified = date2
                }
            }
            if isDir {
                folders.append(
                    FileInfo(
                        fileName: url.lastPathComponent,
                        isFolder: true,
                        url: url,
                        lastModified: lastModified
                    )
                )
            } else {
                var sizeStr = "unknown size"
                if let size = resource.fileSize {
                    sizeStr = formatFileSize(UInt64(size))
                }
                files.append(
                    FileInfo(
                        fileName: url.lastPathComponent,
                        isFolder: false,
                        url: url,
                        size: sizeStr,
                        lastModified: lastModified
                    )
                )
            }
        } else {
            throw ErrorMsg(
                errorDescription: "Cannot read files or folders meta data"
            )
        }
    }
    files.sort {
        $0.url.lastPathComponent.localizedStandardCompare(
            $1.url.lastPathComponent
        ) == .orderedAscending
    }
    folders.sort {
        $0.url.lastPathComponent.localizedStandardCompare(
            $1.url.lastPathComponent
        ) == .orderedAscending
    }
    return (folders, files)
}
