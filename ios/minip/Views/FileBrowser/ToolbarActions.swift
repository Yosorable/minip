//
//  FileBrowserToolbarAction.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import UIKit

extension FileBrowserViewController {
    @objc func selectOrDeselectAll() {
        let itemCount = dataSource.snapshot().numberOfItems
        if (tableView.indexPathsForSelectedRows?.count ?? 0) == itemCount {
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
                toolbarItems = [shareSelectedBtn, copyBtn, moveBtn, deleteBtn, flexibleSpace, moreBtn]
            }
            let enableBtn = (tableView.indexPathsForSelectedRows?.count ?? 0) != 0
            copyBtn.isEnabled = enableBtn
            moveBtn.isEnabled = enableBtn
            deleteBtn.isEnabled = enableBtn
            shareSelectedBtn.isEnabled = enableBtn
            moreBtn.isEnabled = enableBtn
            let itemCount = dataSource.snapshot().numberOfItems
            if itemCount == 0 {
                selectAllBtn.title = i18n("Select All")
                selectAllBtn.isEnabled = false
            } else if (tableView.indexPathsForSelectedRows?.count ?? 0) == itemCount {
                selectAllBtn.title = i18n("Deselect All")
            } else {
                selectAllBtn.title = i18n("Select All")
            }
            selectAllBtn.isEnabled = itemCount != 0
            navigationItem.leftBarButtonItem = selectAllBtn
        } else {
            if folderURL == Global.shared.fileBrowserRootURL {
                navigationItem.leftBarButtonItem = openWebServerBtn
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    fileprivate func checkSelectedItems() -> (isValid: Bool, selectedItemURL: [URL], selectedItemFileInfo: [FileInfo]) {
        var isValid = true
        var selectedItemFileInfo = [FileInfo]()
        let selectedItemURL: [URL] = tableView.indexPathsForSelectedRows?.compactMap {
            guard let fileInfo = dataSource.itemIdentifier(for: $0) else { return nil }
            selectedItemFileInfo.append(fileInfo)
            if fileInfo.url == Global.shared.documentsTrashURL || fileInfo.url == Global.shared.dataFolderURL {
                isValid = false
            }
            return fileInfo.url
        } ?? []
        return (isValid, selectedItemURL, selectedItemFileInfo)
    }

    @objc func deleteSelected() {
        let res = checkSelectedItems()
        let containsCannotDeleteItems = !res.isValid
        let toDeleteURLs = res.selectedItemURL

        logger.debug("[FileBrowser] to delete file: \(toDeleteURLs.map { $0.lastPathComponent })")

        if containsCannotDeleteItems {
            showSimpleError(err: ErrorMsg(errorDescription: "Some files or folders cannot delete"))
            return
        }

        let isInTrashRoot = folderURL == Global.shared.documentsTrashURL
        if toDeleteURLs.count != 0 {
            let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_selected_confirm_message", "\(toDeleteURLs.count)"), preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
            alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { [weak self] _ in
                var successCount = 0
                do {
                    for url in toDeleteURLs {
                        if isInTrashRoot {
                            try FileManager.default.removeItem(at: url)
                        } else {
                            try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                        }
                        successCount += 1
                    }
                    showSimpleSuccess(msg: i18n(isInTrashRoot ? "f.deleted_success" : "f.moved_to_trash"))
                } catch {
                    showSimpleError(err: error)
                }
                self?.toggleSelectMode()
                if successCount > 0 {
                    self?.fetchFilesAndUpdateDataSource()
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

    @objc func shareSelected() {
        let res = checkSelectedItems()
        let avc = UIActivityViewController(activityItems: res.selectedItemURL, applicationActivities: nil)

        avc.popoverPresentationController?.sourceView = view
        avc.popoverPresentationController?.sourceRect = view.bounds

        present(avc, animated: true)
    }

    func compressSelected() {
        let res = checkSelectedItems()
        guard !res.selectedItemFileInfo.isEmpty else { return }
        compress(res.selectedItemFileInfo)
        if tableView.isEditing {
            toggleSelectMode()
        }
    }
}
