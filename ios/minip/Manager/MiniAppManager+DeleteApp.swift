//
//  CreateNewProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import Foundation

extension MiniAppManager {
    func deleteMiniApp(project: InstalledProject, completion: () -> Void) {
        let app = project.appInfo
        let fileManager = FileManager.default
        let dataFolder = Global.shared.projectDataFolderURL.appending(component: app.appId, directoryHint: .isDirectory)
        do {
            try fileManager.trashItem(at: project.rootURL, resultingItemURL: nil)
            for per in MiniAppPermissionTypes.allCases {
                let key = app.appId + "-" + per.rawValue
                try KVStorageManager.shared.deleteValue(forKey: key, namespace: KVStorageManager.privacyNamespace)
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
