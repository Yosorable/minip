//
//  FileBrowserPageViewModel.swift
//  minip
//
//  Created by LZY on 2025/3/15.
//

import SwiftUI

struct FileInfo: Identifiable {
    var fileName: String
    var isFolder: Bool
    var url: URL
    var size: String?

    var id: String {
        return fileName
    }
}

class FileBrowserPageViewModel: ObservableObject {
    @Published var files: [FileInfo] = []
    var path: String

    init(path: String) {
        self.path = path
    }

    func fetchFiles() {
        logger.debug("[fetchFiles] fetch files")
        let fileManager = FileManager.default
        let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: path)
        var res = [FileInfo]()
        do {
            var (folderURLs, fileURLs) = try getFilesAndFolders(in: folderURL)
            folderURLs.sort {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            // set trash folder to first
            if let idx = folderURLs.firstIndex(where: { $0.lastPathComponent == ".Trash" }) {
                folderURLs.insert(folderURLs.remove(at: idx), at: 0)
            }
            fileURLs.sort {
                $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending
            }
            for folderURL in folderURLs {
                res.append(FileInfo(fileName: folderURL.lastPathComponent, isFolder: true, url: folderURL))
            }
            for fileURL in fileURLs {
                var fileInfo = FileInfo(fileName: fileURL.lastPathComponent, isFolder: false, url: fileURL)
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let fileSize = attributes[.size] as? UInt64 {
                    fileInfo.size = formatFileSize(fileSize)
                }
                res.append(fileInfo)
            }
            files = res
        } catch {
            logger.error("[fetchFiles] \(error)")
        }
    }

    func getFilesAndFolders(in directory: URL) throws -> (folders: [URL], files: [URL]) {
        var folders = [URL]()
        var files = [URL]()

        let fileManager = FileManager.default
        let contents = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)

        for content in contents {
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: content.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    folders.append(content)
                } else {
                    files.append(content)
                }
            }
        }

        folders.sort(by: { l, r in
            l.lastPathComponent < r.lastPathComponent
        })

        files.sort(by: { l, r in
            l.lastPathComponent < r.lastPathComponent
        })
        return (folders, files)
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
}
