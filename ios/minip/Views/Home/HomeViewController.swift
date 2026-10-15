//
//  HomeViewController.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import AVFoundation
import SwiftUI
import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITableViewDragDelegate, UITableViewDropDelegate {
    var apps: [InstalledProject] = []

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .insetGrouped)
        tableView.register(AppCell.self, forCellReuseIdentifier: AppCell.identifier)
        return tableView
    }()

    lazy var addProjectBtn: UIBarButtonItem = {
        let menu = UIMenu(children: [
            UIAction(title: String(localized: "Create new project"), image: UIImage(systemName: "folder.badge.plus")) { _ in
                ShowCreateNewProjectAlert(
                    self,
                    onCreatedSuccess: { newApp in
                        self.apps.insert(newApp, at: 0)
                        self.tableView.beginUpdates()
                        self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                        self.tableView.endUpdates()
                    })
            },
            UIAction(title: String(localized: "Load from web"), image: UIImage(systemName: "network")) { _ in
                let vc = DownloadProjectViewController()
                let nvc = PannableNavigationViewController(rootViewController: vc)
                nvc.modalPresentationStyle = .fullScreen
                self.present(nvc, animated: true)
            },
            UIAction(title: String(localized: "Load from file"), image: UIImage(systemName: "folder")) { _ in
                let vc = UIHostingController(rootView: ImportProjectFromFileView())
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            },
        ])

        let addProjectBtn = UIBarButtonItem(image: UIImage(systemName: "plus.square"), menu: menu)

        addProjectBtn.tintColor = .label
        return addProjectBtn
    }()

    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()

    lazy var scanQRCodeButton: UIBarButtonItem = {
        let button = UIBarButtonItem(image: UIImage(systemName: "qrcode.viewfinder"), style: .plain, target: self, action: #selector(scanQRCode))
        button.tintColor = .label
        return button
    }()

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Projects")

        apps = MiniAppManager.shared.getInstalledProjects()
        if Preferences.firstStart && apps.count == 0 {
            Preferences.firstStart = false
            if let newApp = try? MiniAppManager.shared.createMiniApp() {
                apps.append(newApp)
            }
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.dropDelegate = self
        tableView.allowsSelectionDuringEditing = false
        tableView.refreshControl = refreshControl
        view.addSubview(tableView)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        editButtonItem.tintColor = .label
        navigationItem.rightBarButtonItems = [addProjectBtn, editButtonItem]
        navigationItem.leftBarButtonItem = scanQRCodeButton

        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: .appListUpdated, object: nil)
    }

    @objc func refreshData() {
        logger.debug("[HomeViewController] refresh table view data")
        Task {
            let newApps = MiniAppManager.shared.getInstalledProjects()
            await MainActor.run {
                self.apps = newApps
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }

    private func removeProjectFromList(_ project: InstalledProject) {
        guard let row = apps.firstIndex(where: {
            $0.appId == project.appId && $0.rootURL == project.rootURL
        }) else {
            refreshData()
            return
        }

        apps.remove(at: row)
        tableView.beginUpdates()
        tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
        tableView.endUpdates()
    }

    @objc func scanQRCode() {
        let qvc = QRScannerViewController()
        qvc.modalPresentationStyle = .fullScreen
        qvc.onSucceed = { [weak self] code in
            QRCodeHandler.shared.handle(code: code, viewController: self)
        }
        qvc.onFailed = { err in
            showSimpleError(err: err)
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            present(qvc, animated: true)
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        self?.present(qvc, animated: true)
                    }
                } else {
                    DispatchQueue.main.async {
                        let alert = UIAlertController(title: String(localized: "Camera Access Required"), message: String(localized: "Allow camera access in Settings to scan QR codes."), preferredStyle: .alert)
                        alert.addAction(
                            .init(
                                title: String(localized: "OK"), style: .default,
                                handler: { _ in
                                    self?.dismiss(animated: false)
                                }))
                        self?.present(alert, animated: true)
                    }
                }
            }
        default:
            let alert = UIAlertController(title: String(localized: "Camera Access Required"), message: String(localized: "Allow camera access in Settings to scan QR codes."), preferredStyle: .alert)
            alert.addAction(.init(title: String(localized: "OK"), style: .cancel))
            present(alert, animated: true)
        }
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if apps.count == 0 {
            let iconPlaceholder = "\u{FFFC}"
            let message = String(localized: "Tap the \(iconPlaceholder) button in the upper right corner to create new projects.", comment: "The placeholder is the inline add button icon.")
            let messageAttributedString = NSMutableAttributedString(string: message)

            if let symbolImage = UIImage(systemName: "plus.square") {
                let attachment = NSTextAttachment()
                attachment.image = symbolImage.withTintColor(.label)

                let imageString = NSAttributedString(attachment: attachment)
                let iconRange = (message as NSString).range(of: iconPlaceholder)
                if iconRange.location != NSNotFound {
                    messageAttributedString.replaceCharacters(in: iconRange, with: imageString)
                }
            }
            tableView.setEmptyView(
                title: NSAttributedString(string: String(localized: "Nothing here")),
                message: messageAttributedString
            )
        } else {
            tableView.restore()
        }
        return apps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AppCell.identifier, for: indexPath) as! AppCell
        cell.configure(with: apps[indexPath.row])
        return cell
    }

    // MARK: - TableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MiniAppManager.shared.openMiniApp(
            parent: self, project: apps[indexPath.row],
            completion: {
                self.tableView.deselectRow(at: indexPath, animated: false)
            })
    }

    // MARK: - swipe actions

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(
            style: .destructive, title: String(localized: "Delete"),
            handler: { _, _, completion in
                let project = self.apps[indexPath.row]
                let alert = UIAlertController(title: String(localized: "Delete Project"), message: String(localized: "Delete \"\(project.title)\"?"), preferredStyle: .alert)
                let confirm = UIAlertAction(
                    title: String(localized: "Delete"), style: .destructive,
                    handler: { _ in
                        MiniAppManager.shared.deleteMiniApp(
                            project: project,
                            completion: {
                                self.removeProjectFromList(project)
                                completion(true)
                                showSimpleSuccess(msg: String(localized: "Project deleted successfully."))
                            })
                    })
                let cancel = UIAlertAction(
                    title: String(localized: "Cancel"), style: .default,
                    handler: { _ in
                        completion(false)
                    })
                alert.addAction(cancel)
                alert.addAction(confirm)
                self.present(alert, animated: true)
            })

        let settingsAction = UIContextualAction(
            style: .normal, title: String(localized: "Settings"),
            handler: { _, _, completion in
                let vc = MiniAppSettingsViewController(style: .insetGrouped, app: self.apps[indexPath.row].appInfo)
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
                completion(true)
            })

        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, settingsAction])
        return swipeConfiguration
    }

    // MARK: - move item

    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let movedItem = apps.remove(at: fromIndexPath.row)
        apps.insert(movedItem, at: toIndexPath.row)
        var appSortList = Preferences.appSortList
        let movedItemS = appSortList.remove(at: fromIndexPath.row)
        appSortList.insert(movedItemS, at: toIndexPath.row)
        Preferences.appSortList = appSortList
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // MARK: - Context Menu

    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let app = apps[indexPath.row]
        return UIContextMenuConfiguration(identifier: indexPath as NSCopying, previewProvider: nil) { _ in
            let openAction = UIAction(title: String(localized: "Open"), image: UIImage(systemName: "arrow.up.forward.app")) { [weak self] _ in
                guard let self else { return }
                MiniAppManager.shared.openMiniApp(parent: self, project: app, completion: {})
            }

            let settingsAction = UIAction(title: String(localized: "Settings"), image: UIImage(systemName: "gear")) { [weak self] _ in
                guard let self else { return }
                let vc = MiniAppSettingsViewController(style: .insetGrouped, app: app.appInfo)
                vc.hidesBottomBarWhenPushed = true
                self.navigationController?.pushViewController(vc, animated: true)
            }

            let deleteAction = UIAction(title: String(localized: "Delete"), image: UIImage(systemName: "trash"), attributes: .destructive) { [weak self] _ in
                guard let self else { return }
                let alert = UIAlertController(title: String(localized: "Delete Project"), message: String(localized: "Delete \"\(app.title)\"?"), preferredStyle: .alert)
                let confirm = UIAlertAction(title: String(localized: "Delete"), style: .destructive) { _ in
                    MiniAppManager.shared.deleteMiniApp(
                        project: app,
                        completion: {
                            self.removeProjectFromList(app)
                            showSimpleSuccess(msg: String(localized: "Project deleted successfully."))
                        })
                }
                let cancel = UIAlertAction(title: String(localized: "Cancel"), style: .default)
                alert.addAction(cancel)
                alert.addAction(confirm)
                self.present(alert, animated: true)
            }

            return UIMenu(children: [openAction, settingsAction, deleteAction])
        }
    }

    // MARK: - Drag Delegate

    func tableView(_ tableView: UITableView, itemsForBeginning session: any UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = apps[indexPath.row]
        return [dragItem]
    }

    // MARK: - Drop Delegate

    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: any UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        guard tableView.hasActiveDrag else {
            return UITableViewDropProposal(operation: .cancel)
        }
        return UITableViewDropProposal(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: any UITableViewDropCoordinator) {
        guard let destinationIndexPath = coordinator.destinationIndexPath,
            let item = coordinator.items.first,
            let sourceIndexPath = item.sourceIndexPath
        else { return }

        tableView.performBatchUpdates {
            let movedItem = apps.remove(at: sourceIndexPath.row)
            apps.insert(movedItem, at: destinationIndexPath.row)
            var appSortList = Preferences.appSortList
            let movedSortItem = appSortList.remove(at: sourceIndexPath.row)
            appSortList.insert(movedSortItem, at: destinationIndexPath.row)
            Preferences.appSortList = appSortList
            tableView.moveRow(at: sourceIndexPath, to: destinationIndexPath)
        }
        coordinator.drop(item.dragItem, toRowAt: destinationIndexPath)
    }
}
