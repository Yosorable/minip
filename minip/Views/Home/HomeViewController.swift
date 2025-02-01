//
//  HomeViewController.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import UIKit
import SwiftUI

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
                ShowNotImplement()
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

    // MARK: - 左滑action
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete", handler: {_,_, completion in
            self.apps.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        })
        
        let settingsAction = UIContextualAction(style: .normal, title: "Settings", handler: { _,_, completion in
            let ss = MiniAppSettingsViewController()
            let vc = NavableNavigationViewController(rootViewController: ss)
            vc.addPanGesture(vc: ss)
            vc.modalPresentationStyle = .overFullScreen
            self.present(vc, animated: true)
            completion(true)
        })
        
        let swipeConfiguration = UISwipeActionsConfiguration(actions: [deleteAction, settingsAction])
        return swipeConfiguration
    }
    
    // MARK: - 允许拖动排序
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        let movedApp = apps.remove(at: fromIndexPath.row)
        apps.insert(movedApp, at: toIndexPath.row)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }
}
