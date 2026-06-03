//
//  KVStore.swift
//  minip
//
//  Key-value storage backed by the system SQLite (libsqlite3) that the runtime
//  already links for the `sqlite` bridge API — so there's no separate embedded
//  DB dependency. One file (`.data/kv.sqlite`, WAL), one table namespaced by
//  `ns`: each miniapp uses its appId as the namespace; `.privacy` is reserved
//  for permission flags. Statements are prepared once and reused.
//

import Foundation
import SQLite3

/// Value types the KV store accepts. Mirrors the small surface in use:
/// `String` for the `kvstorage` API, `Bool` for permission flags.
protocol KVStorable {
    func kvEncoded() -> String
    static func kvDecoded(_ text: String) -> Self?
}

extension String: KVStorable {
    func kvEncoded() -> String { self }
    static func kvDecoded(_ text: String) -> String? { text }
}

extension Bool: KVStorable {
    func kvEncoded() -> String { self ? "1" : "0" }
    static func kvDecoded(_ text: String) -> Bool? { text == "1" }
}

final class KVStorageManager {
    static let shared = KVStorageManager()

    private let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
    private let lock = NSLock()
    private var db: OpaquePointer?
    private var getStmt: OpaquePointer?
    private var putStmt: OpaquePointer?
    private var delStmt: OpaquePointer?
    private var emptyStmt: OpaquePointer?

    private init() {
        let dir = Global.shared.dataFolderURL
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        let path = dir.appendingPathComponent("kv.sqlite").path
        guard sqlite3_open(path, &db) == SQLITE_OK else {
            logger.error("[KVStorageManager] cannot open kv.sqlite at \(path)")
            db = nil
            return
        }
        exec("PRAGMA journal_mode=WAL;")
        exec("PRAGMA synchronous=NORMAL;")
        exec("CREATE TABLE IF NOT EXISTS kv (ns TEXT NOT NULL, k TEXT NOT NULL, v TEXT, PRIMARY KEY (ns, k));")
        sqlite3_prepare_v2(db, "SELECT v FROM kv WHERE ns=? AND k=?;", -1, &getStmt, nil)
        sqlite3_prepare_v2(db, "INSERT OR REPLACE INTO kv (ns, k, v) VALUES (?, ?, ?);", -1, &putStmt, nil)
        sqlite3_prepare_v2(db, "DELETE FROM kv WHERE ns=? AND k=?;", -1, &delStmt, nil)
        sqlite3_prepare_v2(db, "DELETE FROM kv WHERE ns=?;", -1, &emptyStmt, nil)
    }

    private func exec(_ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // MARK: Namespaces

    /// KV namespace for a miniapp (keyed by appId). `.privacy` is reserved.
    func getDB(dbName: String) -> KVNamespace? {
        if dbName == ".privacy" { return nil }
        return db == nil ? nil : KVNamespace(ns: dbName, manager: self)
    }

    /// Shared namespace holding per-app permission flags.
    func getPrivacyDB() -> KVNamespace? {
        return db == nil ? nil : KVNamespace(ns: ".privacy", manager: self)
    }

    /// No-op: KV data persists across miniapp close (mirrors the prior LMDB
    /// behavior, which only dropped an in-memory handle). The single shared
    /// connection holds no per-namespace state to release.
    func removeDB(dbName: String) {}

    // MARK: Low-level ops (used by KVNamespace)

    fileprivate func get(ns: String, key: String) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        guard let stmt = getStmt else { throw ErrorMsg(errorDescription: "kv store not ready") }
        defer { sqlite3_reset(stmt); sqlite3_clear_bindings(stmt) }
        sqlite3_bind_text(stmt, 1, ns, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, key, -1, SQLITE_TRANSIENT)
        if sqlite3_step(stmt) == SQLITE_ROW, let c = sqlite3_column_text(stmt, 0) {
            return String(cString: c)
        }
        return nil
    }

    fileprivate func put(ns: String, key: String, value: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard let stmt = putStmt else { throw ErrorMsg(errorDescription: "kv store not ready") }
        defer { sqlite3_reset(stmt); sqlite3_clear_bindings(stmt) }
        sqlite3_bind_text(stmt, 1, ns, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, key, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 3, value, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw ErrorMsg(errorDescription: String(cString: sqlite3_errmsg(db)))
        }
    }

    fileprivate func delete(ns: String, key: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard let stmt = delStmt else { throw ErrorMsg(errorDescription: "kv store not ready") }
        defer { sqlite3_reset(stmt); sqlite3_clear_bindings(stmt) }
        sqlite3_bind_text(stmt, 1, ns, -1, SQLITE_TRANSIENT)
        sqlite3_bind_text(stmt, 2, key, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw ErrorMsg(errorDescription: String(cString: sqlite3_errmsg(db)))
        }
    }

    fileprivate func empty(ns: String) throws {
        lock.lock(); defer { lock.unlock() }
        guard let stmt = emptyStmt else { throw ErrorMsg(errorDescription: "kv store not ready") }
        defer { sqlite3_reset(stmt); sqlite3_clear_bindings(stmt) }
        sqlite3_bind_text(stmt, 1, ns, -1, SQLITE_TRANSIENT)
        guard sqlite3_step(stmt) == SQLITE_DONE else {
            throw ErrorMsg(errorDescription: String(cString: sqlite3_errmsg(db)))
        }
    }
}

/// A namespaced view over the shared KV store. API mirrors what the call sites
/// previously used on the LMDB `Database`.
struct KVNamespace {
    let ns: String
    let manager: KVStorageManager

    func get<T: KVStorable>(type: T.Type, forKey key: String) throws -> T? {
        guard let text = try manager.get(ns: ns, key: key) else { return nil }
        return T.kvDecoded(text)
    }

    func put<T: KVStorable>(value: T, forKey key: String) throws {
        try manager.put(ns: ns, key: key, value: value.kvEncoded())
    }

    func deleteValue(forKey key: String) throws {
        try manager.delete(ns: ns, key: key)
    }

    func empty() throws {
        try manager.empty(ns: ns)
    }
}
