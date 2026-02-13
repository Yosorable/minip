//
//  LMDB.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import Foundation
import SwiftLMDB

class KVStorageManager {
    static let shared = KVStorageManager()
    var environment: Environment?
    var dbMap: [String: Database] = .init()
    init() {
        let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appending(component: ".data", directoryHint: .isDirectory)
        let (exist, _) = fileOrFolderExists(path: defaultURL.path)
        do {
            if !exist {
                try FileManager.default.createDirectory(at: defaultURL, withIntermediateDirectories: true)
            }
            environment = try Environment(path: defaultURL.path, flags: [], maxDBs: 128)
        } catch {
            logger.error("[KVStoreManager] \(error)")
        }
    }

    func getDB(dbName: String) -> Database? {
        // built in db
        if dbName == ".privacy" {
            return nil
        }
        guard let res = dbMap[dbName] else {
            let res = try? environment?.openDatabase(named: dbName, flags: [.create])
            dbMap[dbName] = res
            return res
        }
        return res
    }
    
    func getPrivacyDB() -> Database? {
        let dbName = ".privacy"
        guard let res = dbMap[dbName] else {
            let res = try? environment?.openDatabase(named: dbName, flags: [.create])
            dbMap[dbName] = res
            return res
        }
        return res
    }

    func removeDB(dbName: String) {
        dbMap.removeValue(forKey: dbName)
    }
}
