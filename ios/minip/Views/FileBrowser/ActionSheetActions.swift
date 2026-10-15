//
//  ActionSheetActions.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController {
    func rename(fileInfo: FileInfo) {
        if fileInfo.url == Global.shared.documentsTrashURL || fileInfo.url == Global.shared.dataFolderURL {
            showSimpleError(err: ErrorMsg(errorDescription: String(localized: "You cannot rename this folder")))
            return
        }

        let alert = UIAlertController(title: String(localized: "Rename"), message: String(localized: "Enter a file name"), preferredStyle: .alert)
        var textField: UITextField?
        alert.addTextField { tf in
            tf.placeholder = String(localized: "File name")
            tf.text = fileInfo.fileName
            textField = tf
        }
        alert.addAction(UIAlertAction(title: String(localized: "Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: String(localized: "Confirm"), style: .default, handler: { [weak self] _ in
            guard let fileName = textField?.text, let strongSelf = self else {
                return
            }
            if fileName == "" || fileName.contains("/") {
                showSimpleError(err: ErrorMsg(errorDescription: String(localized: "Invalid file name")))
                return
            }
            let fileManager = FileManager.default
            let newURL = strongSelf.folderURL.appending(component: fileName)

            do {
                try fileManager.moveItem(at: fileInfo.url, to: newURL)
                self?.fetchFilesAndUpdateDataSource()
                if strongSelf.folderURL.standardizedFileURL == Global.shared.documentsRootURL.standardizedFileURL {
                    NotificationCenter.default.post(name: .appListUpdated, object: nil)
                }
                showSimpleSuccess(msg: String(localized: "Renamed successfully"))
            } catch {
                showSimpleError(err: error)
            }
        }))
        present(alert, animated: true)
    }

    func copyItem(fileInfo: FileInfo) {
        moveOrCopyFiles(files: [fileInfo], isMove: false)
    }

    func moveItem(fileInfo: FileInfo) {
        moveOrCopyFiles(files: [fileInfo], isMove: true)
    }
}
