//
//  MiniAppPrivacy.swift
//  minip
//
//  Created by LZY on 2025/2/19.
//

import UIKit

enum MiniAppPermissionTypes: String, CaseIterable {
    case camera
    case clipboard
    case installProject
    case getInstalledProjectsList
    case openProject

    func getDescription(app: AppInfo) -> String {
        let name = app.displayName ?? app.name
        switch self {
        case .camera:
            return i18nF("mp.request_camera_permission", name)
        case .clipboard:
            return i18nF("mp.request_clipboard_permission", name)
        case .installProject:
            return i18nF("mp.request_install_project_permission", name)
        case .getInstalledProjectsList:
            return i18nF("mp.request_read_projects_list_permission", name)
        case .openProject:
            return i18nF("mp.request_open_project_permission", name)
        }
    }

    func getTitle() -> String {
        switch self {
        case .camera:
            i18n("mp.camera")
        case .clipboard:
            i18n("mp.clipboard")
        case .installProject:
            i18n("mp.install_project")
        case .getInstalledProjectsList:
            i18n("mp.get_projects_list")
        case .openProject:
            i18n("mp.open_project")
        }
    }
}

extension MiniAppManager {
    func getOrRequestPermission(permissionType: MiniAppPermissionTypes, app: AppInfo? = nil, onSuccess: (() -> Void)? = nil, onFailed: ((Error) -> Void)? = nil, parentVC: UIViewController? = nil) {
        guard let db = KVStorageManager.shared.getPrivacyDB() else {
            let error = ErrorMsg(errorDescription: "[MiniAPPPermision] cannot open permission db")
            logger.error("\(error.localizedDescription)")
            onFailed?(error)
            return
        }
        guard let app = app ?? openedApp else {
            let error = ErrorMsg(errorDescription: "[MiniAPPPermision] not app permission to get")
            logger.error("\(error.localizedDescription)")
            onFailed?(error)
            return
        }
        let key = app.appId + "-" + permissionType.rawValue
        let val = try? db.get(type: Bool.self, forKey: key)
        if val == true {
            onSuccess?()
            return
        } else if val == false {
            onFailed?(ErrorMsg(errorDescription: "Not allow"))
            return
        }

        // request permission
        let alert = UIAlertController(title: i18n("Permission"), message: permissionType.getDescription(app: app), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: i18n("Deny"), style: .cancel, handler: { _ in
            try? db.put(value: false, forKey: key)
            onFailed?(ErrorMsg(errorDescription: "Not allow"))
        }))
        alert.addAction(UIAlertAction(title: i18n("Allow"), style: .default, handler: { _ in
            try? db.put(value: true, forKey: key)
            onSuccess?()
        }))

        (parentVC ?? GetTopViewController())?.present(alert, animated: true)
    }

    func clearAllPermissions() {
        guard let db = KVStorageManager.shared.getPrivacyDB() else {
            return
        }
        try? db.empty()
    }
}
