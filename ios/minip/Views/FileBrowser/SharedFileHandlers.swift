//
//  SharedActions.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import ProgressHUD
import UIKit
import ZIPFoundation

extension FileBrowserViewController {
    func moveOrCopyFiles(files: [FileInfo], isMove: Bool) {
        var message: String
        if files.count == 1 {
            message = i18n(isMove ? "Move" : "Copy") + " " + files.first!.fileName
        } else {
            var fmtStr = ""
            let foldersCnt = files.filter { $0.isFolder }.count
            let filesCnt = files.count - foldersCnt
            if !isMove {
                if foldersCnt == 0 {
                    fmtStr = "f.copy_files_message"
                } else if filesCnt == 0 {
                    fmtStr = "f.copy_folders_message"
                } else {
                    fmtStr = "f.copy_files_folders_message"
                }
            } else {
                if foldersCnt == 0 {
                    fmtStr = "f.move_files_message"
                } else if filesCnt == 0 {
                    fmtStr = "f.move_folders_message"
                } else {
                    fmtStr = "f.move_files_folders_message"
                }
            }
            message = i18nF(fmtStr, "\(files.count)")
        }
        if isMove {
            // check if the files or folder can be moved
            for ele in files {
                if ele.url == Global.shared.documentsTrashURL || ele.url == Global.shared.dataFolderURL {
                    showSimpleError(err: ErrorMsg(errorDescription: files.count == 1 ? "This \(files.first!.isFolder ? "folder" : "file") cannot move" : "Some files or folders cannot move"))
                    return
                }
            }
        }
        logger.debug("[FileBrowser] file to \(isMove ? "move" : "copy"): \(files.map { $0.fileName })")

        let onConfirm = { [weak self] (destinationDirectoryURL: URL) in
            guard let self else { return }
            logger.debug("[FileBrowser] \(isMove ? "move" : "copy") to path: \(destinationDirectoryURL)")
            let sourceURLs = files.map { $0.url }
            let fileManager = FileManager.default

            // Validate: cannot copy/move a folder into itself
            for sourceURL in sourceURLs {
                let destinationURL = destinationDirectoryURL.appendingPathComponent(sourceURL.lastPathComponent)
                if self.isDestinationInsideSource(sourceURL: sourceURL, destinationURL: destinationURL) {
                    showSimpleError(err: ErrorMsg(errorDescription: "Cannot \(isMove ? "move" : "copy") a folder into itself"))
                    return
                }
            }

            // Move to same directory: skip silently
            if isMove {
                let sameDir = sourceURLs.allSatisfy {
                    $0.deletingLastPathComponent().standardizedFileURL == destinationDirectoryURL.standardizedFileURL
                }
                if sameDir {
                    self.fetchFilesAndUpdateDataSource()
                    return
                }
            }

            // Copy to same directory: auto-rename all
            if !isMove {
                let sameDir = sourceURLs.allSatisfy {
                    $0.deletingLastPathComponent().standardizedFileURL == destinationDirectoryURL.standardizedFileURL
                }
                if sameDir {
                    self.performFileOperations(sourceURLs: sourceURLs, destinationDir: destinationDirectoryURL, isMove: false, conflictPolicy: .keepBoth)
                    return
                }
            }

            // Check for conflicts
            let conflicting = sourceURLs.filter {
                fileManager.fileExists(atPath: destinationDirectoryURL.appendingPathComponent($0.lastPathComponent).path)
            }

            if conflicting.isEmpty {
                self.performFileOperations(sourceURLs: sourceURLs, destinationDir: destinationDirectoryURL, isMove: isMove, conflictPolicy: .none)
            } else {
                // Check if any conflict has mismatched types (file vs folder)
                var hasTypeMismatch = false
                for url in conflicting {
                    let destURL = destinationDirectoryURL.appendingPathComponent(url.lastPathComponent)
                    var srcIsDir: ObjCBool = false
                    var dstIsDir: ObjCBool = false
                    fileManager.fileExists(atPath: url.path, isDirectory: &srcIsDir)
                    fileManager.fileExists(atPath: destURL.path, isDirectory: &dstIsDir)
                    if srcIsDir.boolValue != dstIsDir.boolValue { hasTypeMismatch = true; break }
                }

                let names = conflicting.count <= 3
                    ? conflicting.map { $0.lastPathComponent }.joined(separator: ", ")
                    : "\(conflicting.count) items"
                let alert = UIAlertController(
                    title: i18n("Item Already Exists"),
                    message: i18n("\"\(names)\" already exists in this location."),
                    preferredStyle: .alert
                )
                if !hasTypeMismatch {
                    alert.addAction(UIAlertAction(title: i18n("Replace"), style: .destructive) { _ in
                        self.performFileOperations(sourceURLs: sourceURLs, destinationDir: destinationDirectoryURL, isMove: isMove, conflictPolicy: .replace)
                    })
                }
                alert.addAction(UIAlertAction(title: i18n("Keep Both"), style: .default) { _ in
                    self.performFileOperations(sourceURLs: sourceURLs, destinationDir: destinationDirectoryURL, isMove: isMove, conflictPolicy: .keepBoth)
                })
                alert.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel))
                self.present(alert, animated: true)
            }
        }

        let onCancel: () -> Void = { [weak self] in
            self?.fetchFilesAndUpdateDataSource()
        }

        var vcs: [UIViewController] = []
        for vc in navigationController?.viewControllers ?? [] {
            if let url = (vc as? FileBrowserViewController)?.folderURL {
                let vc = FileBrowserViewController(
                    folderURL: url,
                    isModal: true,
                    modalMessage: message,
                    onConfirm: onConfirm,
                    confirmText: i18n(isMove ? "Move" : "Copy"),
                    onCancel: onCancel
                )
                vcs.append(vc)
            }
        }

        let nvc = UINavigationController()
        nvc.setViewControllers(vcs, animated: false)
        nvc.presentationController?.delegate = self
        present(nvc, animated: true)
    }

    private enum ConflictPolicy { case none, replace, keepBoth }

    private func performFileOperations(sourceURLs: [URL], destinationDir: URL, isMove: Bool, conflictPolicy: ConflictPolicy) {
        let fileManager = FileManager.default
        var successCount = 0
        var failCount = 0

        for sourceURL in sourceURLs {
            var destinationURL = destinationDir.appendingPathComponent(sourceURL.lastPathComponent)

            if fileManager.fileExists(atPath: destinationURL.path) {
                switch conflictPolicy {
                case .none:
                    failCount += 1; continue
                case .replace:
                    try? fileManager.removeItem(at: destinationURL)
                case .keepBoth:
                    destinationURL = Self.uniqueDestination(for: sourceURL.lastPathComponent, in: destinationDir)
                }
            }

            do {
                if isMove {
                    try fileManager.moveItem(at: sourceURL, to: destinationURL)
                } else {
                    try fileManager.copyItem(at: sourceURL, to: destinationURL)
                }
                successCount += 1
            } catch {
                failCount += 1
            }
        }

        if failCount == 0 {
            showSimpleSuccess(msg: i18n(isMove ? "Moved successfully" : "Copied successfully"))
        } else {
            showSimpleError(err: ErrorMsg(errorDescription: "\(successCount) succeeded, \(failCount) failed"))
        }
        if navigationController?.isToolbarHidden == false {
            toggleSelectMode()
        }
        fetchFilesAndUpdateDataSource()
    }

    fileprivate func isDestinationInsideSource(sourceURL: URL, destinationURL: URL) -> Bool {
        let standardizedSourceURL = sourceURL.standardizedFileURL
        let standardizedDestinationURL = destinationURL.standardizedFileURL

        var currentURL = standardizedDestinationURL

        while currentURL.pathComponents.count > 1 {
            currentURL.deleteLastPathComponent()
            if currentURL == standardizedSourceURL {
                return true
            }
        }
        return false
    }

    func decompress(_ fileInfo: FileInfo) {
        ProgressHUD.animate("Decompressing", interaction: false)
        Task {
            let parentDir = fileInfo.url.deletingLastPathComponent()
            let fileManager = FileManager.default
            do {
                // extract to temp directory
                let tempDir = fileManager.temporaryDirectory.appending(path: UUID().uuidString)
                try fileManager.unzipItem(at: fileInfo.url, to: tempDir)

                let tempContents = try fileManager.contentsOfDirectory(at: tempDir, includingPropertiesForKeys: nil)

                // single root entry: move it directly; multiple: wrap in a folder
                let itemsToMove: [(source: URL, baseName: String, ext: String)]
                if tempContents.count == 1, let item = tempContents.first {
                    let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
                    let ext = isDir ? "" : (item.pathExtension.isEmpty ? "" : "." + item.pathExtension)
                    let baseName = isDir ? item.lastPathComponent : item.deletingPathExtension().lastPathComponent
                    itemsToMove = [(item, baseName, ext)]
                } else {
                    // rename tempDir itself as the wrapper folder
                    let baseName = fileInfo.fileName.deletingSuffix(".zip")
                    itemsToMove = [(tempDir, baseName, "")]
                }

                for item in itemsToMove {
                    var destName = item.baseName + item.ext
                    var cnt = 1
                    while fileManager.fileExists(atPath: parentDir.appending(path: destName).path) {
                        destName = item.baseName + " \(cnt)" + item.ext
                        cnt += 1
                    }
                    try fileManager.moveItem(at: item.source, to: parentDir.appending(path: destName))
                }

                try? fileManager.removeItem(at: tempDir)
                showSimpleSuccess(msg: "Decompressed successfully")
                self.fetchFilesAndUpdateDataSource()
            } catch {
                showSimpleError(err: error)
            }
        }
    }

    func compress(_ files: [FileInfo]) {
        guard !files.isEmpty else { return }

        ProgressHUD.animate(i18n("Compressing"), interaction: false)
        Task {
            do {
                let baseName: String
                if files.count == 1 {
                    baseName = files[0].url.deletingPathExtension().lastPathComponent
                } else {
                    baseName = folderURL.lastPathComponent
                }

                var destURL = folderURL.appending(component: "\(baseName).zip")
                let fileManager = FileManager.default
                var cnt = 1
                while fileManager.fileExists(atPath: destURL.path) {
                    destURL = folderURL.appending(component: "\(baseName) \(cnt).zip")
                    cnt += 1
                }

                let archive = try Archive(url: destURL, accessMode: .create)

                for file in files {
                    if file.isFolder {
                        let dirURL = file.url.standardizedFileURL
                        let basePath = dirURL.deletingLastPathComponent().path + "/"
                        // add the folder itself
                        try archive.addEntry(with: dirURL.lastPathComponent, fileURL: dirURL)

                        if let enumerator = fileManager.enumerator(at: dirURL, includingPropertiesForKeys: nil) {
                            while let fileURL = enumerator.nextObject() as? URL {
                                let standardizedURL = fileURL.standardizedFileURL
                                let relPath = standardizedURL.path.replacingOccurrences(of: basePath, with: "")
                                try archive.addEntry(with: relPath, fileURL: standardizedURL)
                            }
                        }
                    } else {
                        try archive.addEntry(with: file.url.lastPathComponent, fileURL: file.url)
                    }
                }

                showSimpleSuccess(msg: i18n("Compressed successfully"))
                self.fetchFilesAndUpdateDataSource()
            } catch {
                showSimpleError(err: error)
            }
        }
    }
}
