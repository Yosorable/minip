//
//  ActionSheetActions.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController {
    func rename(fileInfo: FileInfo) {
        if path == "/", fileInfo.fileName == ".Trash" || fileInfo.fileName == ".data" {
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
            if fileName == "" {
                ShowSimpleError(err: ErrorMsg(errorDescription: "Invalid file name"))
                return
            }
            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: strongSelf.path)
            let newURL = folderURL.appendingPolyfill(component: fileName)

            do {
                try fileManager.moveItem(at: fileInfo.url, to: newURL)
                self?.fetchFiles(reloadTableView: true)
                ShowSimpleSuccess(msg: i18n("Renamed successfully"))
            } catch {
                ShowSimpleError(err: error)
            }
        }))
        present(alert, animated: true)
    }
}
