//
//  FileBrowserViewController.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import ProgressHUD
import UIKit

class FileBrowserViewController: UITableViewController {
    let path: String
    var files: [FileInfo] = []

    init(path: String) {
        self.path = path
        super.init(style: .insetGrouped)
        title = path == "/" ? i18n("Files") : (path.splitPolyfill(separator: "/").last ?? "")
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var createFileBtn: UIBarButtonItem = {
        let menu = UIMenu(children: [
            UIAction(title: i18n("f.create_file"), image: UIImage(systemName: "doc")) { [weak self] _ in
                self?.createFile()
            },
            UIAction(title: i18n("f.create_folder"), image: UIImage(systemName: "folder")) { [weak self] _ in
                self?.createFolder()
            },
        ])
        let btn = UIBarButtonItem(image: UIImage(systemName: "plus.app.fill"), menu: menu)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if path == "/.Trash" {
            let btn = UIBarButtonItem(title: i18n("f.clean_trash"), style: .plain, target: self, action: #selector(cleanTrash))
            btn.tintColor = .red
            navigationItem.rightBarButtonItem = btn
        } else if !path.contains("/.Trash") {
            navigationItem.rightBarButtonItem = createFileBtn
        }

        fetchFiles(reloadTableView: false)

        tableView.rowHeight = 44
        tableView.register(FileItemCell.self, forCellReuseIdentifier: FileItemCell.identifier)
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
    }

    var needCheckFileUpdates = false
    override func viewDidDisappear(_ animated: Bool) {
        needCheckFileUpdates = true
    }

    override func viewDidAppear(_ animated: Bool) {
        if needCheckFileUpdates {
            logger.debug("[FileBrowser] \(self.path): checking file updates")
            needCheckFileUpdates = false
            fetchFiles(reloadTableView: true)
        }
    }

    @objc func refreshTableView() {
        fetchFiles(reloadTableView: true)
    }

    deinit {
        logger.debug("[FileBrowser] deinit")
    }
}

extension FileBrowserViewController {
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        files.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FileItemCell.identifier, for: indexPath) as! FileItemCell
        cell.configure(with: files[indexPath.row], isRoot: path == "/")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let fileInfo = files[indexPath.row]
        if fileInfo.isFolder {
            let vc = FileBrowserViewController(path: "\(path == "/" ? "" : path)/\(fileInfo.fileName)")
            navigationController?.pushViewController(vc, animated: true)
        } else {
            var cannotOpen = false
            if let utType = try? fileInfo.url.resourceValues(forKeys: [.contentTypeKey]).contentType {
                if utType.conforms(to: .text) {
                    let vc = CodeEditorViewController(fileInfo: fileInfo)
                    let nvc = PannableNavigationViewController(rootViewController: vc)
                    nvc.modalPresentationStyle = .fullScreen
                    present(nvc, animated: true)
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
                ProgressHUD.failed("Cannot open this file.")
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let fileInfo = files[indexPath.row]
        let cannotDelete = fileInfo.isFolder && path == "/" && fileInfo.fileName == ".Trash"
        let deleteAction = UIContextualAction(style: .destructive, title: i18n("Delete"), handler: { [weak self] _, _, completion in
            if cannotDelete {
                ShowSimpleError(err: ErrorMsg(errorDescription: "You cannot delete this folder"))
                completion(false)
                return
            }
            let onSuccess = {
                self?.files.remove(at: indexPath.row)
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
                completion(true)
            }
            let onError = { err in
                ShowSimpleError(err: err)
                completion(false)
            }
            if fileInfo.isFolder {
                self?.deleteFolder(url: fileInfo.url, onSuccess: onSuccess, onFailed: onError, onCanceled: { completion(false) })
            } else {
                self?.deleteFile(url: fileInfo.url, onSuccess: onSuccess, onFailed: onError, onCanceled: { completion(false) })
            }
        })
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

// MARK: File or Folder Handler

extension FileBrowserViewController {
    func fetchFiles(reloadTableView: Bool, insertedItemName: String? = nil) {
        logger.debug("[FileBrowser] fetching files")
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
            if files != res {
                files = res
                if reloadTableView {
                    logger.debug("[FileBrowser] reload table view")
                    if let insertedItemName = insertedItemName, let idx = res.firstIndex(where: { $0.fileName == insertedItemName }) {
                        tableView.beginUpdates()
                        tableView.insertRows(at: [IndexPath(row: idx, section: 0)], with: .automatic)
                        tableView.endUpdates()
                    } else {
                        tableView.reloadData()
                    }
                }
            } else {
                logger.debug("[FileBrowser] no changes")
            }
        } catch {
            logger.error("[FileBrowser] fetching error: \(error)")
        }
        refreshControl?.endRefreshing()
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

    @objc func cleanTrash() {
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18n("f.clean_trash_confirm"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("f.clean_trash"), style: .destructive, handler: { [weak self] _ in
            CleanTrashAsync {
                ShowSimpleSuccess()
                self?.fetchFiles(reloadTableView: true)
            } onError: { err in
                ShowSimpleError(err: err)
            }
        }))
        alertController.show()
    }

    func createFile() {
        let alertController = UIAlertController(title: i18n("f.create_file"), message: i18n("f.create_file_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = i18n("f.file_name")
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Create"), style: .default, handler: { [weak self] _ in
            guard let fileName = textField?.text, let strongSelf = self else {
                return
            }

            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: strongSelf.path)
            let newFileURL = folderURL.appendingPolyfill(component: fileName)

            if !fileManager.fileExists(atPath: newFileURL.path) {
                if fileManager.createFile(atPath: newFileURL.path, contents: nil) {
                    ShowSimpleSuccess(msg: i18n("created_successfully"))
                    strongSelf.fetchFiles(reloadTableView: true, insertedItemName: fileName)
                } else {
                    ShowSimpleError()
                }
            } else {
                ShowSimpleError(err: ErrorMsg(errorDescription: "File exists"))
            }
        }))
        alertController.show()
    }

    func createFolder() {
        let alertController = UIAlertController(title: i18n("f.create_folder"), message: i18n("f.create_folder_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = i18n("f.folder_name")
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Create"), style: .default, handler: { [weak self] _ in
            guard let fileName = textField?.text, let strongSelf = self else {
                return
            }

            let fileManager = FileManager.default
            let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: strongSelf.path)
            let newFileURL = folderURL.appendingPolyfill(component: fileName)

            if !fileManager.fileExists(atPath: newFileURL.path) {
                do {
                    try fileManager.createDirectory(at: newFileURL, withIntermediateDirectories: false)
                    ShowSimpleSuccess(msg: i18n("created_successfully"))
                    strongSelf.fetchFiles(reloadTableView: true, insertedItemName: fileName)
                } catch {
                    ShowSimpleError(err: error)
                }

            } else {
                ShowSimpleError(err: ErrorMsg(errorDescription: "Folder exists"))
            }
        }))
        alertController.show()
    }

    func deleteFolder(url: URL?, onSuccess: @escaping () -> Void, onFailed: @escaping (Error) -> Void, onCanceled: @escaping () -> Void) {
        guard let url = url else {
            return
        }

        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_folder_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: { _ in
            onCanceled()
        }))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                onSuccess()
            } catch {
                onFailed(error)
            }
        }))
        alertController.show()
    }

    func deleteFile(url: URL?, onSuccess: @escaping () -> Void, onFailed: @escaping (Error) -> Void, onCanceled: @escaping () -> Void) {
        guard let url = url else {
            return
        }
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_file_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: { _ in onCanceled() }))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                onSuccess()
            } catch {
                onFailed(error)
            }
        }))
        alertController.show()
    }
}
