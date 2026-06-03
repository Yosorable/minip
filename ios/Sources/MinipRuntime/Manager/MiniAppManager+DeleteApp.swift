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
        let appFolder = Global.shared.documentsRootURL.appending(component: app.name, directoryHint: .isDirectory)
        let dataFolder = Global.shared.projectDataFolderURL.appending(component: app.appId, directoryHint: .isDirectory)
        do {
            try fileManager.trashItem(at: appFolder, resultingItemURL: nil)
            let db = KVStorageManager.shared.getPrivacyDB()
            for per in MiniAppPermissionTypes.allCases {
                let key = app.appId + "-" + per.rawValue
                try db?.deleteValue(forKey: key)
            }

            if fileManager.fileExists(atPath: dataFolder.path), try fileManager.contentsOfDirectory(atPath: dataFolder.path).isEmpty {
                try fileManager.trashItem(at: dataFolder, resultingItemURL: nil)
            }
        } catch {
            logger.error("[deleteMiniApp] error: \(error.localizedDescription)")
        }
        completion()
    }
}
