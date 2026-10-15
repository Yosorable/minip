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
    let launchURL: String
    init(style: UITableView.Style, app: AppInfo, launchURL: String? = nil) {
        self.app = app
        self.launchURL = launchURL ?? "minip://open/\(app.appId)"
        super.init(style: style)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = String(localized: "Settings")

        if navigationController is BackableNavigationController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .plain, target: self, action: #selector(closePage))
        } else {
            navigationItem.largeTitleDisplayMode = .never
        }

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "PrivacyCell")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "URLSchemeCell")
    }

    @objc func closePage() {
        if navigationController is BackableNavigationController {
            dismiss(animated: true)
        } else {
            navigationController?.popViewController(animated: true)
        }
    }

    lazy var privacySettings: [(title: String, key: String, isEnabled: Bool)] = {
        var res: [(title: String, key: String, isEnabled: Bool)] = []

        for per in MiniAppPermissionTypes.allCases {
            let key = app.appId + "-" + per.rawValue
            do {
                if let value = try KVStorageManager.shared.bool(forKey: key, namespace: KVStorageManager.privacyNamespace) {
                    res.append((per.getTitle(), key, value))
                }
            } catch {
                logger.error("[MiniAppPermission] \(error.localizedDescription)")
            }
        }

        return res
    }()

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return privacySettings.count
        case 1:
            return 1
        default:
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return String(localized: "Privacy")
        case 1:
            return String(localized: "URL Scheme")
        default:
            break
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PrivacyCell", for: indexPath)
            let privacyItem = privacySettings[indexPath.row]
            let privacySwitch = UISwitch()
            privacySwitch.isOn = privacyItem.isEnabled
            privacySwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
            privacySwitch.tag = indexPath.row
            cell.accessoryView = privacySwitch
            cell.selectionStyle = .none

            var content = cell.defaultContentConfiguration()
            content.text = privacyItem.title
            cell.contentConfiguration = content
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "URLSchemeCell", for: indexPath)
            var content = cell.defaultContentConfiguration()
            content.text = String(localized: "Open")
            content.secondaryText = launchURL
            content.secondaryTextProperties.color = .secondaryLabel
            cell.contentConfiguration = content
            cell.accessoryType = .none
            return cell
        default:
            break
        }
        return UITableViewCell()
    }

    // MARK: - TableView Delegate

    // cell tap
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 {
            UIPasteboard.general.string = launchURL
            showSimpleSuccess(msg: String(localized: "Copied to clipboard"))
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - Privacy Switch

    @objc func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        let item = privacySettings[index]
        privacySettings[index].isEnabled = sender.isOn
        do {
            try KVStorageManager.shared.set(sender.isOn, forKey: item.key, namespace: KVStorageManager.privacyNamespace)
        } catch {
            logger.error("[MiniAppPermission] \(error.localizedDescription)")
        }
    }
}
