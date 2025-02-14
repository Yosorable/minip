//
//  MiniAppSettingsViewController.swift
//  minip
//
//  Created by LZY on 2025/2/2.
//

import SwiftUI
import UIKit

class MiniAppSettingsViewController: UITableViewController {
    let app: AppInfo
    init(style: UITableView.Style, app: AppInfo) {
        self.app = app
        super.init(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"

//        let hostingController = UIHostingController(rootView: ScrollView {
//            VStack {
//                Text("Swipe from left to go back")
//                Button {
//                    self.closePage()
//                } label: {
//                    Text("Close")
//                }
//            }
//        })
//
//        addChild(hostingController)
//        view.addSubview(hostingController.view)
//
//        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
//        NSLayoutConstraint.activate([
//            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
//            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor)
//        ])
//
//        hostingController.didMove(toParent: self)

        if navigationController is BackableNavigationController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(closePage))
        } else {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "MiniAppSettingsCell")
    }

    @objc func closePage() {
        if navigationController is BackableNavigationController {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    // 用于存储布尔值的设置项
    var settings: [(title: String, isEnabled: Bool)] = [
        ("Enable Feature", false),
        ("Next Page", false)
    ]

    // MARK: - TableView 数据源方法

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MiniAppSettingsCell", for: indexPath)

        let setting = settings[indexPath.row]
        cell.textLabel?.text = setting.title

        // 如果是开关设置
        if setting.title == "Enable Feature" {
            let featureSwitch = UISwitch()
            featureSwitch.isOn = setting.isEnabled
            featureSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            featureSwitch.tag = indexPath.row // 用tag标记是哪一个设置项
            cell.accessoryView = featureSwitch
            cell.selectionStyle = .none
        } else {
            cell.accessoryType = .disclosureIndicator
        }

        return cell
    }

    // MARK: - TableView Delegate 方法

    // 点击进入下一层设置页面
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == settings.count - 1 { // 如果点击的是“Go to Next Settings”
            let nextSettingsVC = UIViewController()
            nextSettingsVC.view.backgroundColor = .darkGray
            nextSettingsVC.title = "New Page"
            navigationController?.pushViewController(nextSettingsVC, animated: true)
        }
    }

    // MARK: - Switch 状态变化处理方法

    @objc func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        settings[index].isEnabled = sender.isOn
        print("\(settings[index].title) is now \(sender.isOn ? "Enabled" : "Disabled")")
    }
}
