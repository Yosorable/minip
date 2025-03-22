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
            ShowSimpleError(err: ErrorMsg(errorDescription: "You cannot rename this folder"))
            return
        }

        let alert = UIAlertController(title: i18n("Rename"), message: i18n("f.create_file_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alert.addTextField { tf in
            tf.placeholder = i18n("f.file_name")
            tf.text = fileInfo.fileName
            textField = tf
        }
        alert.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel))
        alert.addAction(UIAlertAction(title: i18n("Confirm"), style: .default, handler: { [weak self] _ in
            guard let fileName = textField?.text, let strongSelf = self else {
                return
            }
            if fileName == "" || fileName.contains("/") {
                ShowSimpleError(err: ErrorMsg(errorDescription: "Invalid file name"))
                return
            }
            let fileManager = FileManager.default
            let newURL = strongSelf.folderURL.appendingPolyfill(component: fileName)

            do {
                try fileManager.moveItem(at: fileInfo.url, to: newURL)
                self?.fetchFilesAndUpdateDataSource()
                ShowSimpleSuccess(msg: i18n("Renamed successfully"))
            } catch {
                ShowSimpleError(err: error)
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
