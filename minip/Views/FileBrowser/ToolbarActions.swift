//
//  FileBrowserToolbarAction.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController {
    @objc func selectOrDeselectAll() {
        if (tableView.indexPathsForSelectedRows?.count ?? 0) == files.count {
            for section in 0..<tableView.numberOfSections {
                for row in 0..<tableView.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    tableView.deselectRow(at: indexPath, animated: false)
                }
            }
        } else {
            for section in 0..<tableView.numberOfSections {
                for row in 0..<tableView.numberOfRows(inSection: section) {
                    let indexPath = IndexPath(row: row, section: section)
                    tableView.selectRow(at: indexPath, animated: false, scrollPosition: .none)
                }
            }
        }
        updateToobarButtonStatus()
    }

    func updateToobarButtonStatus() {
        if tableView.isEditing {
            if toolbarItems == nil {
                let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
                toolbarItems = [selectAllBtn, flexibleSpace, copyBtn, flexibleSpace, moveBtn, flexibleSpace, deleteBtn]
            }
            let enableBtn = (tableView.indexPathsForSelectedRows?.count ?? 0) != 0
            copyBtn.isEnabled = enableBtn
            moveBtn.isEnabled = enableBtn
            deleteBtn.isEnabled = enableBtn
            if files.count == 0 {
                selectAllBtn.title = i18n("Select All")
                selectAllBtn.isEnabled = false
            } else if (tableView.indexPathsForSelectedRows?.count ?? 0) == files.count {
                selectAllBtn.title = i18n("Deselect All")
            } else {
                selectAllBtn.title = i18n("Select All")
            }
            selectAllBtn.isEnabled = files.count != 0
            return
        }
    }

    // isValid, selected item urls, selected item indexes
    fileprivate func checkSelectedItems() -> (isValid: Bool, selectedItemURL: [URL], selectedItemIndex: [Int], selectedItemFileInfo: [FileInfo]) {
        var isValid = true
        var selectedItemIndexInTableView = [Int]()
        var selectedItemFileInfo = [FileInfo]()
        let selectedItemURL: [URL] = tableView.indexPathsForSelectedRows?.map {
            let fileInfo = self.files[$0.row]
            selectedItemFileInfo.append(fileInfo)
            selectedItemIndexInTableView.append($0.row)
            if path == "/", fileInfo.fileName == ".Trash" || fileInfo.fileName == ".data" {
                isValid = false
            }
            return fileInfo.url
        } ?? []
        return (isValid, selectedItemURL, selectedItemIndexInTableView, selectedItemFileInfo)
    }

    @objc func deleteSelected() {
        let res = checkSelectedItems()
        let containsCannotDeleteItems = !res.isValid
        let toDeleteURLs = res.selectedItemURL
        let toDeleteIndexInTableView = res.selectedItemIndex

        logger.debug("[FileBrowser] to delete file: \(toDeleteURLs.map { $0.lastPathComponent })")

        if containsCannotDeleteItems {
            ShowSimpleError(err: ErrorMsg(errorDescription: "Some files or folders cannot delete"))
            return
        }

        let isInTrashRoot = path == "/.Trash"
        if toDeleteURLs.count != 0 {
            let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_selected_confirm_message", "\(toDeleteURLs.count)"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { [weak self] _ in
                var successDeleted = [IndexPath]()
                do {
                    for (index, url) in toDeleteURLs.enumerated() {
                        if isInTrashRoot {
                            try FileManager.default.removeItem(at: url)
                        } else {
                            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                        }
                        successDeleted.append(IndexPath(row: toDeleteIndexInTableView[index], section: 0))
                    }
                    ShowSimpleSuccess(msg: i18n(isInTrashRoot ? "f.deleted_success" : "f.moved_to_trash"))
                } catch {
                    ShowSimpleError(err: error)
                }
                self?.toggleSelectMode()
                print(successDeleted)
                if successDeleted.count > 0 {
                    self?.fetchFiles(reloadTableView: false)
                    self?.tableView.beginUpdates()
                    self?.tableView.deleteRows(at: successDeleted, with: .automatic)
                    self?.tableView.endUpdates()
                }
            }))
            present(alertController, animated: true)
        }
    }

    @objc func copySelected() {
        let res = checkSelectedItems()
        moveOrCopyFiles(files: res.selectedItemFileInfo, isMove: false)
    }

    @objc func moveSelected() {
        let res = checkSelectedItems()
        moveOrCopyFiles(files: res.selectedItemFileInfo, isMove: true)
    }
}
