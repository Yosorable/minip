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
            return String(localized: "\(name) requests camera permission")
        case .clipboard:
            return String(localized: "\(name) requests clipboard permission")
        case .installProject:
            return String(localized: "\(name) requests permission to install project")
        case .getInstalledProjectsList:
            return String(localized: "\(name) requests permission to read the project list")
        case .openProject:
            return String(localized: "\(name) requests permission to open another project")
        }
    }

    func getTitle() -> String {
        switch self {
        case .camera:
            String(localized: "Camera")
        case .clipboard:
            String(localized: "Clipboard")
        case .installProject:
            String(localized: "Install Project")
        case .getInstalledProjectsList:
            String(localized: "Get Projects List")
        case .openProject:
            String(localized: "Open Project")
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
            let alert = UIAlertController(title: String(localized: "Permission"), message: permission.getDescription(app: app, projectTitle: projectTitle), preferredStyle: .alert)
            for allowed in [false, true] {
                alert.addAction(UIAlertAction(title: allowed ? String(localized: "Allow") : String(localized: "Deny"), style: allowed ? .default : .cancel) { [weak alert] _ in
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
