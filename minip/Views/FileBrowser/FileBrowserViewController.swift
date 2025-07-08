//
//  FileBrowserViewController.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import ProgressHUD
import SwiftUI
import UIKit

class FileBrowserViewController: UITableViewController {
    let folderURL: URL
    let isModal: Bool
    let modalMessage: String?
    var onConfirm: ((URL) -> Void)?
    var confirmText: String?
    var onCancel: (() -> Void)?
    var files: [FileInfo]!
    var dataSource: UITableViewDiffableDataSource<Int, FileInfo>!

    lazy var openWebServerBtn = {
        let btn = UIBarButtonItem(image: UIImage(systemName: "server.rack"), style: .plain, target: self, action: #selector(openWebServer))
        return btn
    }()

    lazy var selectAllBtn = {
        let btn = UIBarButtonItem(title: i18n("Select All"), style: .plain, target: self, action: #selector(selectOrDeselectAll))
        return btn
    }()

    lazy var shareSelectedBtn = {
        let btn = UIBarButtonItem(title: i18n("Share"), style: .plain, target: self, action: #selector(shareSelected))
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

    init(folderURL: URL, isModal: Bool = false, modalMessage: String? = nil, onConfirm: ((URL) -> Void)? = nil, confirmText: String? = nil, onCancel: (() -> Void)? = nil) {
        self.folderURL = folderURL
        self.isModal = isModal
        self.modalMessage = modalMessage
        self.onConfirm = onConfirm
        self.confirmText = confirmText
        self.onCancel = onCancel
        super.init(style: .insetGrouped)

        let isInRoot = folderURL == Global.shared.fileBrowserRootURL
        if isInRoot, isModal {
            title = "/"
        } else {
            title = isInRoot ? i18n("Files") : folderURL.lastPathComponent
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
                    self?.createFileOrFolder(isFolder: false)
                }
            )
        }
        actions.append(
            UIAction(title: i18n("f.create_folder"), image: UIImage(systemName: "folder")) { [weak self] _ in
                self?.createFileOrFolder(isFolder: true)
            }
        )
        let menu = UIMenu(children: actions)
        let btn = UIBarButtonItem(image: UIImage(systemName: isModal ? "plus" : "plus.app.fill"), menu: menu)
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        if !isModal {
            if folderURL == Global.shared.documentsTrashURL {
                let btn = UIBarButtonItem(image: UIImage(systemName: "trash.fill"), style: .plain, target: self, action: #selector(cleanTrash))
                navigationItem.rightBarButtonItems = [btn, selectButton]
            } else {
                if folderURL == Global.shared.fileBrowserRootURL {
                    navigationItem.leftBarButtonItem = openWebServerBtn
                }
                navigationItem.rightBarButtonItems = [createFileBtn, selectButton]
            }
        } else {
            navigationItem.rightBarButtonItems = [createFileBtn]
            let modalCancelBtn = UIBarButtonItem(title: i18n("Cancel"), style: .plain, target: self, action: #selector(dismissModal))
            let modalConfirmBtn = UIBarButtonItem(title: confirmText ?? i18n("Confirm"), style: .plain, target: self, action: #selector(confirmModal))
            let flexibleSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            if let msg = modalMessage {
                let msgLabel = UILabel()
                msgLabel.text = msg
                msgLabel.textColor = .secondaryLabel
                msgLabel.font = UIFont.preferredFont(forTextStyle: .footnote)
                let msgBtn = UIBarButtonItem()
                msgBtn.customView = msgLabel
                toolbarItems = [modalCancelBtn, flexibleSpace, msgBtn, flexibleSpace, modalConfirmBtn]
            } else {
                toolbarItems = [modalCancelBtn, flexibleSpace, modalConfirmBtn]
            }
            navigationController?.setToolbarHidden(false, animated: false)
        }

        tableView.register(FileItemCell.self, forCellReuseIdentifier: FileItemCell.identifier)
        configureDataSource()
        fetchFilesAndUpdateDataSource()

        tableView.rowHeight = 44
        if !isModal {
            tableView.allowsMultipleSelectionDuringEditing = true
        }

        if !isModal {
            refreshControl = UIRefreshControl()
            refreshControl?.addTarget(self, action: #selector(refreshTableView), for: .valueChanged)
        }
    }

    // TODO: replace mannually refresh data
//    private var folderFD: CInt = -1
//    private var source: DispatchSourceFileSystemObject?
//    func startMonitoring() {
//        folderFD = open(folderURL.path, O_EVTONLY)
//        guard folderFD >= 0 else {
//            logger.error("Failed to open folder: \(self.folderURL)")
//            return
//        }
//
//        source = DispatchSource.makeFileSystemObjectSource(fileDescriptor: folderFD, eventMask: [.write, .delete, .rename], queue: DispatchQueue.global())
//        source?.setEventHandler { [weak self] in
//            guard let self = self else {
//                return
//            }
//            let url = self.folderURL
//            print("[FD Monitoring] \(url) has changes")
//        }
//        let fd = folderFD
//        source?.setCancelHandler {
//            close(fd)
//        }
//        source?.resume()
//    }
//
//    func stopMonitoring() {
//        source?.cancel()
//        source = nil
//    }

    var needCheckFileUpdates = false
    override func viewDidDisappear(_ animated: Bool) {
        needCheckFileUpdates = true
    }

    override func viewDidAppear(_ animated: Bool) {
        if needCheckFileUpdates {
            lazy var fn = { [weak self] in
                let res = self?.folderURL.path.splitPolyfill(separator: Global.shared.fileBrowserRootURL.path).last ?? "unknown path"
                return res == "" ? "/" : res
            }
            logger.debug("[FileBrowser] \"\(fn())\": checking file updates")
            needCheckFileUpdates = false
            fetchFilesAndUpdateDataSource()
        }
    }

    @objc func refreshTableView() {
        fetchFilesAndUpdateDataSource()
    }

    @objc func toggleSelectMode() {
        let editing = tableView.isEditing

        tableView.setEditing(!editing, animated: true)
        selectButton.title = i18n(editing ? "Select" : "Cancel")
        updateToobarButtonStatus()
        navigationController?.setToolbarHidden(!tableView.isEditing, animated: true)
        navigationItem.hidesBackButton = !editing
    }

    @objc func openWebServer() {
        let vc = UIHostingController(rootView: FileServerView())

        present(vc, animated: true)
    }

    @objc func dismissModal() {
        dismiss(animated: true)
        onCancel?()
    }

    @objc func confirmModal() {
        dismiss(animated: true)
        onConfirm?(folderURL)
    }

    deinit {
        logger.debug("[FileBrowser] deinit")
    }
}

// MARK: File or Folder Handler

extension FileBrowserViewController {
    func fetchFilesAndUpdateDataSource() {
        logger.debug("[FileBrowser] fetching files")
        do {
            var (folderURLs, fileURLs) = try listFilesAndFolders(in: folderURL)
            if folderURL == Global.shared.documentsRootURL {
                if let idx = folderURLs.firstIndex(where: { $0.url == Global.shared.documentsTrashURL }) {
                    folderURLs.insert(folderURLs.remove(at: idx), at: 0)
                }
            }
            let allFilesAndFolders = folderURLs + fileURLs

            if files != allFilesAndFolders {
                files = allFilesAndFolders
                logger.debug("[FileBrowser] refreshing table view")
                updateDataSource()

                if tableView.isEditing == true {
                    toggleSelectMode()
                }
            } else {
                logger.debug("[FileBrowser] no changes")
            }
        } catch {
            showSimpleError(err: error)
            if files == nil {
                files = []
                updateDataSource()
            }
        }
        refreshControl?.endRefreshing()
    }

    @objc func cleanTrash() {
        if tableView.isEditing, (tableView.indexPathsForSelectedRows?.count ?? 0) > 0 {
            deleteSelected()
            return
        }
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18n("f.clean_trash_confirm"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("f.clean_trash"), style: .destructive, handler: { [weak self] _ in
            cleanTrashAsync {
                showSimpleSuccess()

                self?.fetchFilesAndUpdateDataSource()

                if self?.tableView.isEditing == true {
                    self?.toggleSelectMode()
                }
            } onError: { err in
                showSimpleError(err: err)
            }
        }))
        present(alertController, animated: true)
    }

    func createFileOrFolder(isFolder: Bool) {
        let alertController = UIAlertController(title: i18n(isFolder ? "f.create_folder" : "f.create_file"), message: i18n(isFolder ? "f.create_folder_tip" : "f.create_file_tip"), preferredStyle: .alert)
        var textField: UITextField?
        alertController.addTextField { tf in
            tf.placeholder = i18n(isFolder ? "f.folder_name" : "f.file_name")
            textField = tf
        }
        alertController.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: i18n("Create"), style: .default, handler: { [weak self] _ in
            guard let fileName = textField?.text, let strongSelf = self else {
                return
            }
            if fileName == "" {
                showSimpleError(err: ErrorMsg(errorDescription: isFolder ? "Invalid folder name" : "Invalid file name"))
                return
            }

            let fileManager = FileManager.default
            let newFileURL = strongSelf.folderURL.appendingPolyfill(component: fileName)

            if !fileManager.fileExists(atPath: newFileURL.path) {
                do {
                    if isFolder {
                        try fileManager.createDirectory(at: newFileURL, withIntermediateDirectories: false)
                    } else {
                        try Data().write(to: newFileURL)
                    }
                    showSimpleSuccess(msg: i18n("created_successfully"))
                    strongSelf.fetchFilesAndUpdateDataSource()
                } catch {
                    showSimpleError(err: error)
                }

            } else {
                showSimpleError(err: ErrorMsg(errorDescription: isFolder ? "Folder exists" : "File exists"))
            }
        }))
        present(alertController, animated: true)
    }

    func deleteFileOrFolder(isFolder: Bool, url: URL?, onSuccess: @escaping () -> Void, onFailed: @escaping (Error) -> Void, onCanceled: @escaping () -> Void) {
        guard let url = url else {
            return
        }
        let isInTrashRoot = folderURL == Global.shared.documentsTrashURL
        let alertController = UIAlertController(title: i18n("Confirm"), message: i18nF(isFolder ? "f.delete_folder_confirm_message" : "f.delete_file_confirm_message", url.lastPathComponent), preferredStyle: .alert)
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
