//
//  CreateNewProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import Foundation

extension MiniAppManager {
    func deleteMiniApp(app: AppInfo, completion: () -> Void) {
        let fileManager = FileManager.default
        let appFolder = Global.shared.documentsRootURL.appendingPolyfill(path: app.name)
        do {
            try fileManager.trashItem(at: appFolder, resultingItemURL: nil)
            let db = KVStorageManager.shared.getPrivacyDB()
            for per in MiniAppPermissionTypes.allCases {
                let key = app.appId + "-" + per.rawValue
                try db?.deleteValue(forKey: key)
            }
        } catch {
            logger.error("[deleteMiniApp] error: \(error.localizedDescription)")
        }
        completion()
    }
}
