//
//  HomeViewController.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import UIKit
import SwiftUI
import Defaults

class HomeViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var apps: [AppInfo] = []
    
    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .insetGrouped)
        tableView.register(AppCell.self, forCellReuseIdentifier: AppCell.identifier)
        return tableView
    }()
    
    lazy var addProjectBtn: UIBarButtonItem = {
        let menu = UIMenu(children: [
            UIAction(title: "Create new project", image: UIImage(systemName: "folder.badge.plus")) {act in
                ShowCreateNewProjectAlert(self, onCreatedSuccess: {
                    self.refreshData()
                })
            },
            UIAction(title: "Load from web", image: UIImage(systemName: "network")) {act in
                let vc = UIHostingController(rootView: DownloadProjectView())
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            },
            UIAction(title: "Load from file", image: UIImage(systemName: "folder")) {act in
                let vc = UIHostingController(rootView: ImportProjectFromFileView())
                vc.modalPresentationStyle = .fullScreen
                self.present(vc, animated: true)
            },
        ])
        
        let addProjectBtn = UIBarButtonItem(image: UIImage(systemName: "plus.square"), menu: menu)

        addProjectBtn.tintColor = UIColor(.primary)
        return addProjectBtn
    }()
    
    lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        return control
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Projects"
        self.navigationController?.navigationBar.prefersLargeTitles = true

        self.apps = MiniAppManager.shared.getAppInfos()
        
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
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        editButtonItem.tintColor = UIColor(.primary)
        navigationItem.rightBarButtonItems = [addProjectBtn, editButtonItem]
        
        
    }
    
    @objc func refreshData() {
        Task {
            let newApps = MiniAppManager.shared.getAppInfos()
            await MainActor.run {
                self.apps = newApps
                self.tableView.reloadData()
                self.refreshControl.endRefreshing()
            }
        }
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
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: {_,_, completion in
            let app = self.apps[indexPath.row]
            let alert = UIAlertController(title: "Delete Project", message: "Are to sure to delete \(app.displayName ?? app.name)", preferredStyle: .alert)
            let confirm = UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
                MiniAppManager.shared.deleteMiniAPp(app: self.apps[indexPath.row], completion: {
                    self.apps.remove(at: indexPath.row)
                    tableView.beginUpdates()
                    tableView.deleteRows(at: [indexPath], with: .automatic)
                    tableView.endUpdates()
                    completion(true)
                    ShowSimpleSuccess(msg: "Project deleted successfully.")
                })
            })
            let cancel = UIAlertAction(title: "Cancel", style: .default, handler: { _ in
                completion(false)
            })
            alert.addAction(cancel)
            alert.addAction(confirm)
            self.present(alert, animated: true)
        })
        
        let settingsAction = UIContextualAction(style: .normal, title: "Settings", handler: { _,_, completion in
            let vc = MiniAppSettingsViewController(style: .insetGrouped)
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
        let movedItem = self.apps.remove(at: fromIndexPath.row)
        self.apps.insert(movedItem, at: toIndexPath.row)
        let movedItemS = Defaults[.appSortList].remove(at: fromIndexPath.row)
        Defaults[.appSortList].insert(movedItemS, at: toIndexPath.row)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
}
