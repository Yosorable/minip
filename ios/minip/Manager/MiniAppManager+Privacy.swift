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

    func getDescription(app: AppInfo, projectTitle: String? = nil) -> String {
        let name = projectTitle ?? app.displayName ?? app.name
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
        guard let app = app ?? openedApp else {
            let error = ErrorMsg(errorDescription: "[MiniAPPPermision] not app permission to get")
            logger.error("\(error.localizedDescription)")
            onFailed?(error)
            return
        }
        let key = app.appId + "-" + permissionType.rawValue
        let val: Bool?
        do {
            val = try KVStorageManager.shared.bool(forKey: key, namespace: KVStorageManager.privacyNamespace)
        } catch {
            logger.error("[MiniAppPermission] \(error.localizedDescription)")
            onFailed?(error)
            return
        }
        if val == true {
            onSuccess?()
            return
        } else if val == false {
            onFailed?(ErrorMsg(errorDescription: "Not allow"))
            return
        }

        // request permission
        let projectTitle = openedProject?.appId == app.appId ? openedProject?.title : nil
        let alert = UIAlertController(title: i18n("Permission"), message: permissionType.getDescription(app: app, projectTitle: projectTitle), preferredStyle: .alert)
        alert.addAction(
            UIAlertAction(
                title: i18n("Deny"), style: .cancel,
                handler: { _ in
                    try? KVStorageManager.shared.set(false, forKey: key, namespace: KVStorageManager.privacyNamespace)
                    onFailed?(ErrorMsg(errorDescription: "Not allow"))
                }))
        alert.addAction(
            UIAlertAction(
                title: i18n("Allow"), style: .default,
                handler: { _ in
                    try? KVStorageManager.shared.set(true, forKey: key, namespace: KVStorageManager.privacyNamespace)
                    onSuccess?()
                }))

        (parentVC ?? getTopViewController())?.present(alert, animated: true)
    }

    func clearAllPermissions() {
        try? KVStorageManager.shared.clear(namespace: KVStorageManager.privacyNamespace)
    }
}
