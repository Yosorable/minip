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
    let isModal: Bool
    var onConfirm: ((URL) -> Void)?
    var confirmText: String?
    var onCancel: (() -> Void)?
    var files: [FileInfo] = []

    lazy var openWebServerBtn = {
        let btn = UIBarButtonItem(image: UIImage(systemName: "server.rack"), style: .plain, target: self, action: #selector(openWebServer))
        return btn
    }()

    lazy var selectAllBtn = {
        let btn = UIBarButtonItem(title: i18n("Select All"), style: .plain, target: self, action: #selector(selectOrDeselectAll))
        return btn
    }()

    lazy var copyBtn = {
        let btn = UIBarButtonItem(title: i18n("Copy"), style: .plain, target: self, action: #selector(copySelected))
        return btn
    }()

    lazy var moveBtn = {
        let btn = UIBarButtonItem(title: i18n("Move"), style: .plain, target: self, action: #selector(moveSelected))
        return btn
    }()

    lazy var deleteBtn = {
        let btn = UIBarButtonItem(image: UIImage(systemName: "trash.fill"), style: .plain, target: self, action: #selector(deleteSelected))
        return btn
    }()

    lazy var selectButton = {
        let btn = UIBarButtonItem(title: i18n("Select"), style: .plain, target: self, action: #selector(toggleSelectMode))
        return btn
    }()

    init(path: String, isModal: Bool = false, onConfirm: ((URL) -> Void)? = nil, confirmText: String? = nil, onCancel: (() -> Void)? = nil) {
        self.path = path
        self.isModal = isModal
        self.onConfirm = onConfirm
        self.confirmText = confirmText
        self.onCancel = onCancel
        super.init(style: .insetGrouped)
        if path == "/", isModal {
            title = "/"
        } else {
            title = path == "/" ? i18n("Files") : (path.splitPolyfill(separator: "/").last ?? "")
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var createFileBtn: UIBarButtonItem = {
        var actions = [UIAction]()
        if !isModal {
            actions.append(
                UIAction(title: i18n("f.create_file"), image: UIImage(systemName: "doc")) { [weak self] _ in
                    self?.createFile()
                }
            )
        }
        actions.append(
            UIAction(title: i18n("f.create_folder"), image: UIImage(systemName: "folder")) { [weak self] _ in
                self?.createFolder()
            }
        )
        let menu = UIMenu(children: actions)
        let btn = UIBarButtonItem(image: UIImage(systemName: "plus.app.fill"), menu: menu)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if !isModal {
            if path == "/.Trash" {
                let btn = UIBarButtonItem(image: UIImage(systemName: "trash.fill"), style: .plain, target: self, action: #selector(cleanTrash))
                navigationItem.rightBarButtonItems = [btn, selectButton]
            } else {
                if path == "/" {
                    navigationItem.leftBarButtonItem = openWebServerBtn
                }
                navigationItem.rightBarButtonItems = [createFileBtn, selectButton]
            }
        } else {
            navigationItem.rightBarButtonItems = [createFileBtn]
            let modalCancelBtn = UIBarButtonItem(title: i18n("Cancel"), style: .plain, target: self, action: #selector(dismissModal))
            let modalConfirmBtn = UIBarButtonItem(title: confirmText ?? i18n("Confirm"), style: .plain, target: self, action: #selector(confirmModal))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            toolbarItems = [modalCancelBtn, flexibleSpace, modalConfirmBtn]
            navigationController?.setToolbarHidden(false, animated: false)
        }

        fetchFiles(reloadTableView: false)

        tableView.rowHeight = 44
        if !isModal {
            tableView.allowsMultipleSelectionDuringEditing = true
        }
        tableView.register(FileItemCell.self, forCellReuseIdentifier: FileItemCell.identifier)

        if !isModal {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        }
    }

    var needCheckFileUpdates = false
    override func viewDidDisappear(_ animated: Bool) {
        needCheckFileUpdates = true
    }

    override func viewDidAppear(_ animated: Bool) {
        if needCheckFileUpdates {
            let pathStr = path
            logger.debug("[FileBrowser] \"\(pathStr)\": checking file updates")
            needCheckFileUpdates = false
            fetchFiles(reloadTableView: true)
        }
        if !isModal && !tableView.isEditing {
            updateToobarButtonStatus()
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }

    @objc func refreshTableView() {
        fetchFiles(reloadTableView: true)
    }

    @objc func toggleSelectMode() {
        if tableView.isEditing {
            tableView.setEditing(false, animated: true)
            selectButton.title = i18n("Select")
        } else {
            tableView.setEditing(true, animated: true)
            selectButton.title = i18n("Cancel")
        }
        updateToobarButtonStatus()
        navigationController?.setToolbarHidden(!tableView.isEditing, animated: true)
    }

    @objc func openWebServer() {
        ShowSimpleError(err: ErrorMsg(errorDescription: "Not implemented"))
    }

    @objc func dismissModal() {
        dismiss(animated: true)
        onCancel?()
    }

    @objc func confirmModal() {
        dismiss(animated: true)
        let fileManager = FileManager.default
        let folderURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: path)
        onConfirm?(folderURL)
    }

    deinit {
        logger.debug("[FileBrowser] deinit")
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
        if tableView.isEditing, (tableView.indexPathsForSelectedRows?.count ?? 0) > 0 {
            deleteSelected()
            return
        }
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18n("f.clean_trash_confirm"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("f.clean_trash"), style: .destructive, handler: { [weak self] _ in
            CleanTrashAsync {
                ShowSimpleSuccess()
                self?.fetchFiles(reloadTableView: false)
                let deletedRows = self?.tableView.indexPathsForVisibleRows ?? []
                if deletedRows.count > 0 {
                    self?.tableView.beginUpdates()
                    self?.tableView.deleteRows(at: deletedRows, with: .automatic)
                    self?.tableView.endUpdates()
                }
                if self?.tableView.isEditing == true {
                    self?.toggleSelectMode()
                }
            } onError: { err in
                ShowSimpleError(err: err)
            }
        }))
        present(alertController, animated: true)
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
            if fileName == "" {
                ShowSimpleError(err: ErrorMsg(errorDescription: "Invalid file name"))
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
        present(alertController, animated: true)
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
        present(alertController, animated: true)
    }

    func deleteFolder(url: URL?, onSuccess: @escaping () -> Void, onFailed: @escaping (Error) -> Void, onCanceled: @escaping () -> Void) {
        guard let url = url else {
            return
        }
        let isInTrashRoot = path == "/.Trash"
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_folder_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: { _ in
            onCanceled()
        }))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                if isInTrashRoot {
                    try FileManager.default.removeItem(at: url)
                } else {
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                }
                onSuccess()
            } catch {
                onFailed(error)
            }
        }))
        present(alertController, animated: true)
    }

    func deleteFile(url: URL?, onSuccess: @escaping () -> Void, onFailed: @escaping (Error) -> Void, onCanceled: @escaping () -> Void) {
        guard let url = url else {
            return
        }
        let isInTrashRoot = path == "/.Trash"
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF("f.delete_file_confirm_message", url.lastPathComponent), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: { _ in onCanceled() }))
        alertController.addAction(UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
            do {
                if isInTrashRoot {
                    try FileManager.default.removeItem(at: url)
                } else {
                    try FileManager.default.trashItem(at: url, resultingItemURL: nil)
                }
                onSuccess()
            } catch {
                onFailed(error)
            }
        }))
        present(alertController, animated: true)
    }
}
