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
            return "\(name) requests camera permission"
        case .clipboard:
            return "\(name) requests clipboard permission"
        case .installProject:
            return "\(name) requests permission to install project"
        case .getInstalledProjectsList:
            return "\(name) requests permission to read the project list"
        case .openProject:
            return "\(name) requests permission to open another project"
        }
    }

    func getTitle() -> String {
        switch self {
        case .camera:
            "Camera"
        case .clipboard:
            "Clipboard"
        case .installProject:
            "Install Project"
        case .getInstalledProjectsList:
            "Get Projects List"
        case .openProject:
            "Open Project"
        }
    }
}

extension MiniAppManager {
    func getOrRequestPermission(permissionType: MiniAppPermissionTypes, app: AppInfo? = nil, onSuccess: (()->Void)? = nil, onFailed: ((Error)->Void)? = nil, parentVC: UIViewController? = nil) {
        guard let db = KVStorageManager.shared.getPrivacyDB() else {
            let error = ErrorMsg(errorDescription: "[MiniAPPPermision] cannot open permission db")
            logger.error("\(error.localizedDescription)")
            onFailed?(error)
            return
        }
        guard let app = app ?? self.openedApp else {
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
        let alert = UIAlertController(title: "Permission", message: permissionType.getDescription(app: app), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Deny", style: .cancel, handler: { act in
            try? db.put(value: false, forKey: key)
            onFailed?(ErrorMsg(errorDescription: "Not allow"))
        }))
        alert.addAction(UIAlertAction(title: "Allow", style: .default, handler: { act in
            try? db.put(value: true, forKey: key)
            onSuccess?()
        }))
        
        (parentVC ?? GetTopViewController())?.present(alert, animated: true)
    }
}
