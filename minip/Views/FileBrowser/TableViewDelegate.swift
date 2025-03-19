//
//  TableViewDelegate.swift
//  minip
//
//  Created by LZY on 2025/3/17.
//

import ProgressHUD
import UIKit

extension FileBrowserViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if files.count == 0 {
            let messageAttributedString = NSMutableAttributedString(string: i18n("f.empty_folder_msg_p1"))

            if let symbolImage = UIImage(systemName: "plus.app.fill") {
                let attachment = NSTextAttachment()
                attachment.image = symbolImage.withTintColor(view.tintColor)

                let imageString = NSAttributedString(attachment: attachment)
                messageAttributedString.append(imageString)
            }
            messageAttributedString.append(NSAttributedString(string: i18n("f.empty_folder_msg_p2")))
            tableView.setEmptyView(
                title: NSAttributedString(string: i18n("f.empty_folder")),
                message: self.isModal ? NSAttributedString() : (self.folderURL == Global.shared.documentsTrashURL ? NSAttributedString(string: i18n("f.empty_trash_msg")) : messageAttributedString)
            )
        } else {
            tableView.restore()
        }
        return files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileItemCell.identifier, for: indexPath) as! FileItemCell
        cell.configure(with: files[indexPath.row])
        return cell
    }

    override func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if tableView.isEditing {
            updateToobarButtonStatus()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileInfo = files[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        if tableView.isEditing {
            updateToobarButtonStatus()
            return
        }
        if fileInfo.isFolder {
            let vc = FileBrowserViewController(folderURL: fileInfo.url, isModal: isModal, modalMessage: modalMessage, onConfirm: onConfirm, confirmText: confirmText, onCancel: onCancel)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            if !isModal {
                var cannotOpen = false
                if let utType = try? fileInfo.url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                    if utType.conforms(to: .text) {
                        let vc = CodeEditorViewController(fileInfo: fileInfo)
                        let nvc = PannableNavigationViewController(rootViewController: vc)
                        nvc.modalPresentationStyle = .fullScreen
                        present(nvc, animated: true)
                    } else if utType.conforms(to: .propertyList) {
                        do {
                            var data = try Data(contentsOf: fileInfo.url)
                            if let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) {
                                data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
                            }

                            if let xmlString = String(data: data, encoding: .utf8) {
                                let vc = PannableNavigationViewController(rootViewController: CodeEditorViewController(fileInfo: fileInfo, readyOnlyText: xmlString))
                                vc.modalPresentationStyle = .fullScreen
                                self.present(vc, animated: true)
                            } else {
                                throw ErrorMsg()
                            }
                        } catch {
                            cannotOpen = true
                        }
                    } else if utType.conforms(to: .image) {
                        let imageVC = ImagePreviewViewController(imageURL: fileInfo.url)
                        imageVC.title = fileInfo.fileName
                        let nvc = PannableNavigationViewController(rootViewController: imageVC)
                        nvc.modalPresentationStyle = .fullScreen
                        nvc.overrideUserInterfaceStyle = .dark
                        present(nvc, animated: true)
                    } else {
                        cannotOpen = true
                    }
                } else {
                    cannotOpen = true
                }

                if cannotOpen {
                    let alert = UIAlertController(title: fileInfo.fileName, message: i18n("f.select_file_type"), preferredStyle: .actionSheet)
                    alert.addAction(UIAlertAction(title: i18n("Text"), style: .default, handler: { [weak self] _ in
                        let vc = CodeEditorViewController(fileInfo: fileInfo)
                        let nvc = PannableNavigationViewController(rootViewController: vc)
                        nvc.modalPresentationStyle = .fullScreen
                        self?.present(nvc, animated: true)
                    }))
                    alert.addAction(UIAlertAction(title: i18n("Image"), style: .default, handler: { [weak self] _ in
                        let imageVC = ImagePreviewViewController(imageURL: fileInfo.url)
                        imageVC.title = fileInfo.fileName
                        let nvc = PannableNavigationViewController(rootViewController: imageVC)
                        nvc.modalPresentationStyle = .fullScreen
                        nvc.overrideUserInterfaceStyle = .dark
                        self?.present(nvc, animated: true)
                    }))
                    alert.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel))

                    alert.popoverPresentationController?.sourceView = cell
                    alert.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero

                    present(alert, animated: true)
                }
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if isModal {
            return nil
        }

        let fileInfo = files[indexPath.row]
        let cell = tableView.cellForRow(at: indexPath)
        let cannotDelete = fileInfo.url == Global.shared.documentsTrashURL || fileInfo.url == Global.shared.projectsDataFolderURL
        let isInTrashRoot = folderURL == Global.shared.documentsTrashURL

        let onDeleteSuccess = { [weak self] in
            self?.files.remove(at: indexPath.row)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.endUpdates()
            ShowSimpleSuccess(msg: i18n(isInTrashRoot ? "f.deleted_success" : "f.moved_to_trash"))
        }
        let onDeleteError = { err in
            ShowSimpleError(err: err)
        }

        let deleteAction = UIContextualAction(style: .destructive, title: i18n("Delete"), handler: { [weak self] _, _, completion in
            if cannotDelete {
                ShowSimpleError(err: ErrorMsg(errorDescription: "You cannot delete this folder"))
                completion(false)
                return
            }

            if fileInfo.isFolder {
                self?.deleteFolder(url: fileInfo.url, onSuccess: {
                    onDeleteSuccess()
                    completion(true)
                }, onFailed: {
                    onDeleteError($0)
                    completion(false)
                }, onCanceled: { completion(false) })
            } else {
                self?.deleteFile(url: fileInfo.url, onSuccess: {
                    onDeleteSuccess()
                    completion(true)
                }, onFailed: {
                    onDeleteError($0)
                    completion(false)
                }, onCanceled: { completion(false) })
            }
        })
        let moreAction = UIContextualAction(style: .normal, title: i18n("More"), handler: { [weak self] _, _, completion in
            let alert = UIAlertController(title: fileInfo.fileName, message: i18n(fileInfo.isFolder ? "Folder" : "File") + (fileInfo.isFolder ? "" : " (\(fileInfo.size ?? "unknown size"))"), preferredStyle: .actionSheet)

            alert.addAction(UIAlertAction(title: i18n("Share"), style: .default, handler: { _ in
                let avc = UIActivityViewController(activityItems: [fileInfo.url], applicationActivities: nil)

                avc.popoverPresentationController?.sourceView = cell
                avc.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero

                self?.present(avc, animated: true)
            }))
            alert.addAction(UIAlertAction(title: i18n("Copy"), style: .default, handler: { _ in
                self?.copyItem(fileInfo: fileInfo)
            }))
            alert.addAction(UIAlertAction(title: i18n("Move"), style: .default, handler: { _ in
                self?.moveItem(fileInfo: fileInfo)
            }))
            alert.addAction(UIAlertAction(title: i18n("Rename"), style: .default, handler: { _ in
                self?.rename(fileInfo: fileInfo)
            }))
            alert.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
                if cannotDelete {
                    ShowSimpleError(err: ErrorMsg(errorDescription: "You cannot delete this folder"))
                    return
                }
                self?.deleteFile(url: fileInfo.url, onSuccess: onDeleteSuccess, onFailed: onDeleteError, onCanceled: {})
            }))
            alert.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel))
            alert.popoverPresentationController?.sourceView = cell
            alert.popoverPresentationController?.sourceRect = cell?.bounds ?? .zero
            self?.present(alert, animated: true)
            completion(true)
        })
        return UISwipeActionsConfiguration(actions: [deleteAction, moreAction])
    }
}
