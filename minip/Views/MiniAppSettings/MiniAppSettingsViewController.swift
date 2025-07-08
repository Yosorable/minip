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
        title = i18n("Settings")

        if navigationController is BackableNavigationController {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "chevron.backward"), style: .done, target: self, action: #selector(closePage))
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
            let db = KVStorageManager.shared.getPrivacyDB()
            let key = app.appId + "-" + per.rawValue
            if let val = try? db?.get(type: Bool.self, forKey: key) {
                res.append((per.getTitle(), key, val))
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
            return i18n("Privacy")
        case 1:
            return "URL Scheme"
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
            content.text = "Open"
            content.secondaryText = "minip://open/\(app.appId)"
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
            UIPasteboard.general.string = "minip://open/\(app.appId)"
            showSimpleSuccess(msg: "Copied to clipboard successfully.")
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }

    // MARK: - Privacy Switch

    @objc func switchChanged(_ sender: UISwitch) {
        let index = sender.tag
        let item = privacySettings[index]
        privacySettings[index].isEnabled = sender.isOn
        if let db = KVStorageManager.shared.getPrivacyDB() {
            do {
                try db.put(value: sender.isOn, forKey: item.key)
            } catch {
                logger.error("[MiniAppPermission] \(error.localizedDescription)")
            }
        }
    }
}
