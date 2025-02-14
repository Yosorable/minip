//
//  CreateNewProject.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import Foundation

extension MiniAppManager {
    func deleteMiniAPp(app: AppInfo, completion: () -> Void) {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let appFolder = documentsURL.appendingPolyfill(path: app.name)
        do {
            try fileManager.trashItem(at: appFolder, resultingItemURL: nil)
        } catch {}
        completion()
    }
}
