//
//  SharedActions.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController {
    func moveOrCopyFiles(files: [FileInfo], isMove: Bool) {
        if isMove {
            if path == "/" {
                for ele in files {
                    if ele.isFolder, ele.fileName == ".Trash" || ele.fileName == ".data" {
                        ShowSimpleError(err: ErrorMsg(errorDescription: files.count == 1 ? "This \(files.first!.isFolder ? "folder" : "file") cannot move" : "Some files or folders cannot move"))
                        return
                    }
                }
            }
        }
        logger.debug("[FileBrowser] file to \(isMove ? "move" : "copy"): \(files.map { $0.fileName })")
        let vc = UINavigationController(
            rootViewController:
            FileBrowserViewController(
                path: "/",
                isModal: true,
                onConfirm: { [weak self] destinationDirectoryURL in
                    logger.debug("[FileBrowser] \(isMove ? "move" : "copy") to path: \(destinationDirectoryURL)")
                    let sourceURLs = files.map { $0.url }

                    let fileManager = FileManager.default

                    do {
                        // check existance
                        for sourceURL in sourceURLs {
                            let destinationURL = destinationDirectoryURL.appendingPathComponent(sourceURL.lastPathComponent)
                            if fileManager.fileExists(atPath: destinationURL.path) {
                                throw ErrorMsg(errorDescription: i18n("Some files with same names already exist"))
                            }
                        }

                        // move or copy
                        for sourceURL in sourceURLs {
                            let destinationURL = destinationDirectoryURL.appendingPathComponent(sourceURL.lastPathComponent)
                            if isMove {
                                try fileManager.moveItem(at: sourceURL, to: destinationURL)
                            } else {
                                try fileManager.copyItem(at: sourceURL, to: destinationURL)
                            }
                        }
                        ShowSimpleSuccess(msg: i18n(isMove ? "Moved successfully" : "Copied successfully"))
                        if self?.tableView.isEditing == true {
                            self?.toggleSelectMode()
                        }
                        self?.fetchFiles(reloadTableView: true)
                    } catch {
                        ShowSimpleError(err: error)
                    }
                },
                confirmText: i18n(isMove ? "Move" : "Copy")
            )
        )
        present(vc, animated: true)
    }
}
