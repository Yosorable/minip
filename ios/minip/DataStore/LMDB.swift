//
//  LMDB.swift
//  minip
//
//  Created by ByteDance on 2023/7/15.
//

import Foundation
import SwiftLMDB

/// Read/write access to the legacy LMDB store.
///
/// Keep this type isolated from the active KV implementation so the legacy
/// dependency can be removed under the cleanup conditions documented on
/// `KVStorageManager` without changing the active SQLite implementation.
final class LegacyLMDBStorage {
    private let environment: Environment
    private var databaseCache: [String: Database] = [:]

    static func storeExists(in directoryURL: URL) -> Bool {
        FileManager.default.fileExists(atPath: directoryURL.appendingPathComponent("data.mdb").path)
    }

    init(directoryURL: URL, createIfNeeded: Bool) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: directoryURL.path) {
            guard createIfNeeded else {
                throw ErrorMsg(errorDescription: "Legacy KV storage does not exist")
            }
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        }

        environment = try Environment(path: directoryURL.path, flags: [], maxDBs: 128)
    }

    func databaseNames() throws -> [String] {
        let database = try environment.openDatabase()
        let names = try database.map { entry in
            guard let name = String(data: entry.key, encoding: .utf8) else {
                throw ErrorMsg(errorDescription: "Legacy KV storage contains an invalid database name")
            }
            return name
        }
        guard names.count == database.count else {
            throw ErrorMsg(errorDescription: "Cannot enumerate every legacy KV database")
        }
        return names
    }

    func entries(inDatabaseNamed name: String) throws -> [(key: Data, value: Data)] {
        let database = try environment.openDatabase(named: name)
        let entries = database.map { ($0.key, $0.value) }
        guard entries.count == database.count else {
            throw ErrorMsg(errorDescription: "Cannot read every entry in a legacy KV database")
        }
        return entries
    }

    func string(forKey key: String, namespace: String) throws -> String? {
        try database(named: namespace).get(type: String.self, forKey: key)
    }

    func set(_ value: String, forKey key: String, namespace: String) throws {
        try database(named: namespace).put(value: value, forKey: key)
    }

    func bool(forKey key: String, namespace: String) throws -> Bool? {
        try database(named: namespace).get(type: Bool.self, forKey: key)
    }

    func set(_ value: Bool, forKey key: String, namespace: String) throws {
        try database(named: namespace).put(value: value, forKey: key)
    }

    func deleteValue(forKey key: String, namespace: String) throws {
        try database(named: namespace).deleteValue(forKey: key)
    }

    func clear(namespace: String) throws {
        try database(named: namespace).empty()
    }

    func release(namespace: String) {
        databaseCache.removeValue(forKey: namespace)
    }

    private func database(named name: String) throws -> Database {
        if let database = databaseCache[name] {
            return database
        }
        let database = try environment.openDatabase(named: name, flags: [.create])
        databaseCache[name] = database
        return database
    }
}
