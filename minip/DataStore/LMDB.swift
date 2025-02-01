//
//  LMDB.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import Foundation
import SwiftLMDB

class KVStoreManager {
    static let shared = KVStoreManager()
    var environment: Environment? = nil
    var dbMap: [String: Database] = [String: Database]()
    init() {
        let defaultURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPolyfill(path: ".store")
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
