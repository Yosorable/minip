//
//  HomeViewController.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import Defaults
import SwiftUI
import UIKit

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var apps: [AppInfo] = []

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .insetGrouped)
        tableView.register(AppCell.self, forCellReuseIdentifier: AppCell.identifier)
        return tableView
    }()

    lazy var addProjectBtn: UIBarButtonItem = {
        let menu = UIMenu(children: [
            UIAction(title: i18n("home.menu.create_project"), image: UIImage(systemName: "folder.badge.plus")) { _ in
                ShowCreateNewProjectAlert(self, onCreatedSuccess: { newApp in
                    self.apps.insert(newApp, at: 0)
                    self.tableView.beginUpdates()
                    self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
                    self.tableView.endUpdates()
                })
            },
            UIAction(title: i18n("home.menu.load_from_web"), image: UIImage(systemName: "network")) { _ in
                let vc = DownloadProjectViewController()
                let nvc = PannableNavigationViewController(rootViewController: vc)
                nvc.modalPresentationStyle = .fullScreen
                self.present(nvc, animated: true)
            },
            UIAction(title: i18n("home.menu.load_from_file"), image: UIImage(systemName: "folder")) { _ in
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
        title = i18n("Projects")

        apps = MiniAppManager.shared.getAppInfos()
        if Defaults[.firstStart] && apps.count == 0 {
            Defaults[.firstStart] = false
            if let newApp = try? MiniAppManager.shared.createMiniApp() {
                apps.append(newApp)
            }
        }

        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelectionDuringEditing = true
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
            let newApps = MiniAppManager.shared.getAppInfos()
            await MainActor.run {
                self.apps = newApps
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
    }

    @objc func scanQRCode() {
        let qvc = QRScannerViewController()
        qvc.modalPresentationStyle = .fullScreen
        qvc.onSucceed = { [weak self] code in
            QRCodeHandler.shared.handle(code: code, viewController: self)
        }
        qvc.onFailed = { err in
            ShowSimpleError(err: err)
        }
        present(qvc, animated: true)
    }

    // MARK: - TableView DataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return apps.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: AppCell.identifier, for: indexPath) as! AppCell
        cell.configure(with: apps[indexPath.row])
        return cell
    }

    // MARK: - TableView Delegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        MiniAppManager.shared.openMiniApp(parent: self, appInfo: apps[indexPath.row], completion: {
            self.tableView.deselectRow(at: indexPath, animated: false)
        })
    }

    // MARK: - swipe actions

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: i18n("Delete"), handler: { _, _, completion in
            let app = self.apps[indexPath.row]
            let alert = UIAlertController(title: i18n("home.delete_alert_title"), message: i18nF("delete_alert_confirm_message", app.displayName ?? app.name), preferredStyle: .alert)
            let confirm = UIAlertAction(title: i18n("Delete"), style: .destructive, handler: { _ in
                MiniAppManager.shared.deleteMiniAPp(app: self.apps[indexPath.row], completion: {
                    self.apps.remove(at: indexPath.row)
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    tableView.endUpdates()
                    completion(true)
                    ShowSimpleSuccess(msg: i18n("delete_successfully"))
                })
            })
            let cancel = UIAlertAction(title: i18n("Cancel"), style: .default, handler: { _ in
                completion(false)
            })
            alert.addAction(cancel)
            alert.addAction(confirm)
            self.present(alert, animated: true)
        })

        let settingsAction = UIContextualAction(style: .normal, title: i18n("Settings"), handler: { _, _, completion in
            let vc = MiniAppSettingsViewController(style: .insetGrouped, app: self.apps[indexPath.row])
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
        let movedItemS = Defaults[.appSortList].remove(at: fromIndexPath.row)
        Defaults[.appSortList].insert(movedItemS, at: toIndexPath.row)
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
}
