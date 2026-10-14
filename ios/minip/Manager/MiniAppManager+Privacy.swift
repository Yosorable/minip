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
    @MainActor
    func requirePermission(_ permission: MiniAppPermissionTypes, app: AppInfo, parent: UIViewController) async throws {
        let key = app.appId + "-" + permission.rawValue
        let denied = MinipError(.permissionDenied, "Permission was not granted", details: ["permission": .string(permission.rawValue)])
        if let allowed = try KVStorageManager.shared.bool(forKey: key, namespace: KVStorageManager.privacyNamespace) {
            guard allowed else { throw denied }
            return
        }
        guard parent.viewIfLoaded?.window != nil, parent.presentedViewController == nil else {
            throw MinipError(.invalidState, "The page cannot present a permission request right now")
        }
        let projectTitle = openedProject?.appId == app.appId ? openedProject?.title : nil
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let completion = BridgeContinuation(continuation)
            var decision: Result<Void, Error> = .failure(denied)
            let alert = UIAlertController(title: i18n("Permission"), message: permission.getDescription(app: app, projectTitle: projectTitle), preferredStyle: .alert)
            for allowed in [false, true] {
                alert.addAction(UIAlertAction(title: i18n(allowed ? "Allow" : "Deny"), style: allowed ? .default : .cancel) { [weak alert] _ in
                    do {
                        try KVStorageManager.shared.set(allowed, forKey: key, namespace: KVStorageManager.privacyNamespace)
                        decision = allowed ? .success(()) : .failure(denied)
                    } catch { decision = .failure(error) }
                    alert?.dismiss(animated: true) { completion.finish(decision) }
                })
            }
            parent.present(alert, animated: true)
            AlertDismissalObserver.attach(to: alert) { completion.finish(decision) }
        }
    }

    func clearAllPermissions() {
        try? KVStorageManager.shared.clear(namespace: KVStorageManager.privacyNamespace)
    }
}
