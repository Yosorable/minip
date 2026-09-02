//
//  SQLiteKVStorage.swift
//  minip
//
//  Created by Codex on 2026/9/2.
//

import Foundation
import SQLite3

/// SQLite-backed storage for mini-app KV data and Minip permission state.
///
/// The LMDB migration is intentionally one-way: after the transaction and its
/// marker commit, every read and write uses SQLite. Legacy LMDB files remain on
/// disk as a recovery snapshot and are never modified by the SQLite path.
///
/// Migration cleanup: users may skip app releases, so do not remove the LMDB
/// migrator merely because this version has been available for a while. Remove
/// it only when direct upgrades from every LMDB-backed release are no longer
/// supported, or after another compatible migrator replaces it. At that point,
/// remove `LegacyLMDBStorage`, the SwiftLMDB dependency, and the cutover branches
/// below; the SQLite database itself remains unchanged.
final class KVStorageManager {
    static let shared = KVStorageManager()
    static let privacyNamespace = ".privacy"

    private let lock = NSRecursiveLock()
    private let dataDirectoryURL: URL
    private let cutoverMarkerURL: URL

    private var sqliteStorage: SQLiteKVStorage?
    private var legacyStorage: LegacyLMDBStorage?

    private init() {
        dataDirectoryURL = Global.shared.dataFolderURL
        cutoverMarkerURL = dataDirectoryURL.appendingPathComponent(".kv-storage-v2-migrated")
        configureStorage()
    }

    func string(forKey key: String, namespace: String) throws -> String? {
        try validate(key: key)
        return try withLock { () -> String? in
            if let sqliteStorage {
                guard let data = try sqliteStorage.data(forKey: Data(key.utf8), namespace: namespace) else {
                    return nil
                }
                guard let value = String(data: data, encoding: .utf8) else {
                    throw ErrorMsg(errorDescription: "KV storage contains a value that is not valid UTF-8")
                }
                return value
            }
            if let legacyStorage {
                return try legacyStorage.string(forKey: key, namespace: namespace)
            }
            throw storageUnavailableError()
        }
    }

    func set(_ value: String, forKey key: String, namespace: String) throws {
        try validate(key: key)
        try withLock {
            if let sqliteStorage {
                try sqliteStorage.set(Data(value.utf8), forKey: Data(key.utf8), namespace: namespace)
            } else if let legacyStorage {
                try legacyStorage.set(value, forKey: key, namespace: namespace)
            } else {
                throw storageUnavailableError()
            }
        }
    }

    func bool(forKey key: String, namespace: String) throws -> Bool? {
        try validate(key: key)
        return try withLock { () -> Bool? in
            if let sqliteStorage {
                guard let data = try sqliteStorage.data(forKey: Data(key.utf8), namespace: namespace) else {
                    return nil
                }
                guard data.count == 1, let value = data.first else {
                    throw ErrorMsg(errorDescription: "KV storage contains an invalid Boolean value")
                }
                return value != 0
            }
            if let legacyStorage {
                return try legacyStorage.bool(forKey: key, namespace: namespace)
            }
            throw storageUnavailableError()
        }
    }

    func set(_ value: Bool, forKey key: String, namespace: String) throws {
        try validate(key: key)
        try withLock {
            if let sqliteStorage {
                try sqliteStorage.set(Data([value ? UInt8(1) : UInt8(0)]), forKey: Data(key.utf8), namespace: namespace)
            } else if let legacyStorage {
                try legacyStorage.set(value, forKey: key, namespace: namespace)
            } else {
                throw storageUnavailableError()
            }
        }
    }

    func deleteValue(forKey key: String, namespace: String) throws {
        try validate(key: key)
        try withLock {
            if let sqliteStorage {
                try sqliteStorage.deleteValue(forKey: Data(key.utf8), namespace: namespace)
            } else if let legacyStorage {
                try legacyStorage.deleteValue(forKey: key, namespace: namespace)
            } else {
                throw storageUnavailableError()
            }
        }
    }

    func clear(namespace: String) throws {
        try withLock {
            if let sqliteStorage {
                try sqliteStorage.clear(namespace: namespace)
            } else if let legacyStorage {
                try legacyStorage.clear(namespace: namespace)
            } else {
                throw storageUnavailableError()
            }
        }
    }

    func removeDB(dbName: String) {
        withLock {
            legacyStorage?.release(namespace: dbName)
        }
    }

    private func configureStorage() {
        let fileManager = FileManager.default
        let cutoverWasCompleted = fileManager.fileExists(atPath: cutoverMarkerURL.path)

        do {
            try fileManager.createDirectory(at: dataDirectoryURL, withIntermediateDirectories: true)

            let sqliteURL = dataDirectoryURL.appendingPathComponent("kv-storage.sqlite3")
            let storage = try SQLiteKVStorage(url: sqliteURL, createIfNeeded: !cutoverWasCompleted)

            // Once the sidecar exists, LMDB is stale. Missing SQLite state must
            // fail closed instead of silently restoring old data or permissions.
            if cutoverWasCompleted {
                guard try storage.isLegacyMigrationCompleted() else {
                    throw ErrorMsg(errorDescription: "SQLite KV migration state is missing after cutover")
                }
                sqliteStorage = storage
                logger.debug("[KVStorage] using SQLite storage")
                return
            }

            if LegacyLMDBStorage.storeExists(in: dataDirectoryURL) {
                let legacy = try LegacyLMDBStorage(directoryURL: dataDirectoryURL, createIfNeeded: false)
                let migrationResult = try storage.migrate(from: legacy)
                logger.info("[KVStorage] migrated \(migrationResult.entryCount) entries from \(migrationResult.namespaceCount) LMDB databases")
            } else {
                try storage.markLegacyMigrationCompleted()
                logger.debug("[KVStorage] no legacy LMDB storage found")
            }

            // Persist the cutover before exposing SQLite to callers. If this
            // fails, the catch path keeps LMDB active and retries next launch.
            try writeCutoverMarker()
            sqliteStorage = storage
        } catch {
            logger.error("[KVStorage] cannot initialize SQLite storage: \(error.localizedDescription)")

            if cutoverWasCompleted || fileManager.fileExists(atPath: cutoverMarkerURL.path) {
                logger.error("[KVStorage] refusing to use stale LMDB data after SQLite cutover")
                return
            }

            do {
                legacyStorage = try LegacyLMDBStorage(directoryURL: dataDirectoryURL, createIfNeeded: true)
                logger.info("[KVStorage] falling back to legacy LMDB storage")
            } catch {
                logger.error("[KVStorage] cannot initialize legacy storage: \(error.localizedDescription)")
            }
        }
    }

    private func writeCutoverMarker() throws {
        try Data("1".utf8).write(to: cutoverMarkerURL, options: .atomic)
    }

    private func storageUnavailableError() -> ErrorMsg {
        ErrorMsg(errorDescription: "KV storage is unavailable")
    }

    private func validate(key: String) throws {
        if key.isEmpty {
            throw ErrorMsg(errorDescription: "KV storage key cannot be empty")
        }
    }

    private func withLock<T>(_ operation: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try operation()
    }
}

private final class SQLiteKVStorage {
    struct MigrationResult {
        let namespaceCount: Int
        let entryCount: Int
    }

    private static let migrationKey = "legacy-lmdb-v1"
    private let sqliteTransient = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
    private var database: OpaquePointer?

    init(url: URL, createIfNeeded: Bool) throws {
        var database: OpaquePointer?
        var flags = SQLITE_OPEN_READWRITE | SQLITE_OPEN_FULLMUTEX
        if createIfNeeded {
            flags |= SQLITE_OPEN_CREATE
        }
        let result = sqlite3_open_v2(
            url.path,
            &database,
            flags,
            nil
        )
        guard result == SQLITE_OK, let database else {
            let message = database.map { String(cString: sqlite3_errmsg($0)) } ?? "Cannot open SQLite database"
            if let database {
                sqlite3_close_v2(database)
            }
            throw ErrorMsg(errorDescription: message)
        }

        self.database = database
        sqlite3_busy_timeout(database, 5_000)

        do {
            try execute("PRAGMA journal_mode = WAL")
            try execute("PRAGMA synchronous = FULL")
            try execute(
                """
                CREATE TABLE IF NOT EXISTS kv_storage (
                    namespace TEXT NOT NULL,
                    storage_key BLOB NOT NULL,
                    value BLOB NOT NULL,
                    PRIMARY KEY (namespace, storage_key)
                ) WITHOUT ROWID
                """)
            try execute(
                """
                CREATE TABLE IF NOT EXISTS kv_storage_metadata (
                    metadata_key TEXT PRIMARY KEY NOT NULL,
                    value TEXT NOT NULL
                ) WITHOUT ROWID
                """)
        } catch {
            sqlite3_close_v2(database)
            self.database = nil
            throw error
        }
    }

    deinit {
        if let database {
            sqlite3_close_v2(database)
        }
    }

    func isLegacyMigrationCompleted() throws -> Bool {
        let statement = try prepare("SELECT 1 FROM kv_storage_metadata WHERE metadata_key = ? LIMIT 1")
        defer { sqlite3_finalize(statement) }

        try bind(Self.migrationKey, at: 1, to: statement)
        let result = sqlite3_step(statement)
        if result == SQLITE_ROW {
            return true
        }
        guard result == SQLITE_DONE else {
            throw sqliteError("Cannot read KV migration state")
        }
        return false
    }

    func markLegacyMigrationCompleted() throws {
        try inTransaction {
            try setMigrationCompleted()
        }
    }

    func migrate(from legacyStorage: LegacyLMDBStorage) throws -> MigrationResult {
        let namespaceNames = try legacyStorage.databaseNames()
        var expectedEntryCount = 0

        try inTransaction {
            try execute("DELETE FROM kv_storage")

            let statement = try prepare("INSERT INTO kv_storage (namespace, storage_key, value) VALUES (?, ?, ?)")
            defer { sqlite3_finalize(statement) }

            for namespace in namespaceNames {
                let entries = try legacyStorage.entries(inDatabaseNamed: namespace)
                expectedEntryCount += entries.count

                for entry in entries {
                    sqlite3_reset(statement)
                    sqlite3_clear_bindings(statement)
                    try bind(namespace, at: 1, to: statement)
                    try bind(entry.key, at: 2, to: statement)
                    try bind(entry.value, at: 3, to: statement)
                    guard sqlite3_step(statement) == SQLITE_DONE else {
                        throw sqliteError("Cannot migrate legacy KV entry")
                    }
                }
            }

            let migratedEntryCount = try entryCount()
            guard migratedEntryCount == expectedEntryCount else {
                throw ErrorMsg(errorDescription: "Legacy KV migration validation failed")
            }
            try setMigrationCompleted()
        }

        return MigrationResult(namespaceCount: namespaceNames.count, entryCount: expectedEntryCount)
    }

    func data(forKey key: Data, namespace: String) throws -> Data? {
        let statement = try prepare("SELECT value FROM kv_storage WHERE namespace = ? AND storage_key = ? LIMIT 1")
        defer { sqlite3_finalize(statement) }

        try bind(namespace, at: 1, to: statement)
        try bind(key, at: 2, to: statement)

        let result = sqlite3_step(statement)
        if result == SQLITE_DONE {
            return nil
        }
        guard result == SQLITE_ROW else {
            throw sqliteError("Cannot read KV entry")
        }

        let byteCount = Int(sqlite3_column_bytes(statement, 0))
        guard byteCount > 0 else {
            return Data()
        }
        guard let bytes = sqlite3_column_blob(statement, 0) else {
            throw sqliteError("Cannot read KV value")
        }
        return Data(bytes: bytes, count: byteCount)
    }

    func set(_ value: Data, forKey key: Data, namespace: String) throws {
        let statement = try prepare(
            """
            INSERT INTO kv_storage (namespace, storage_key, value)
            VALUES (?, ?, ?)
            ON CONFLICT(namespace, storage_key) DO UPDATE SET value = excluded.value
            """)
        defer { sqlite3_finalize(statement) }

        try bind(namespace, at: 1, to: statement)
        try bind(key, at: 2, to: statement)
        try bind(value, at: 3, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError("Cannot write KV entry")
        }
    }

    func deleteValue(forKey key: Data, namespace: String) throws {
        let statement = try prepare("DELETE FROM kv_storage WHERE namespace = ? AND storage_key = ?")
        defer { sqlite3_finalize(statement) }

        try bind(namespace, at: 1, to: statement)
        try bind(key, at: 2, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError("Cannot delete KV entry")
        }
    }

    func clear(namespace: String) throws {
        let statement = try prepare("DELETE FROM kv_storage WHERE namespace = ?")
        defer { sqlite3_finalize(statement) }

        try bind(namespace, at: 1, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError("Cannot clear KV storage")
        }
    }

    private func setMigrationCompleted() throws {
        let statement = try prepare(
            """
            INSERT INTO kv_storage_metadata (metadata_key, value)
            VALUES (?, '1')
            ON CONFLICT(metadata_key) DO UPDATE SET value = excluded.value
            """)
        defer { sqlite3_finalize(statement) }

        try bind(Self.migrationKey, at: 1, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else {
            throw sqliteError("Cannot save KV migration state")
        }
    }

    private func entryCount() throws -> Int {
        let statement = try prepare("SELECT COUNT(*) FROM kv_storage")
        defer { sqlite3_finalize(statement) }

        guard sqlite3_step(statement) == SQLITE_ROW else {
            throw sqliteError("Cannot validate KV migration")
        }
        return Int(sqlite3_column_int64(statement, 0))
    }

    private func inTransaction(_ operation: () throws -> Void) throws {
        try execute("BEGIN IMMEDIATE")
        do {
            try operation()
            try execute("COMMIT")
        } catch {
            try? execute("ROLLBACK")
            throw error
        }
    }

    private func execute(_ sql: String) throws {
        guard let database else {
            throw ErrorMsg(errorDescription: "SQLite KV storage is closed")
        }

        var errorMessage: UnsafeMutablePointer<CChar>?
        let result = sqlite3_exec(database, sql, nil, nil, &errorMessage)
        guard result == SQLITE_OK else {
            let message = errorMessage.map { String(cString: $0) } ?? String(cString: sqlite3_errmsg(database))
            sqlite3_free(errorMessage)
            throw ErrorMsg(errorDescription: message)
        }
    }

    private func prepare(_ sql: String) throws -> OpaquePointer {
        guard let database else {
            throw ErrorMsg(errorDescription: "SQLite KV storage is closed")
        }

        var rawStatement: OpaquePointer?
        let result = sqlite3_prepare_v2(database, sql, -1, &rawStatement, nil)
        guard result == SQLITE_OK, let statement = rawStatement else {
            if let rawStatement {
                sqlite3_finalize(rawStatement)
            }
            throw sqliteError("Cannot prepare KV storage query")
        }
        return statement
    }

    private func bind(_ value: String, at index: Int32, to statement: OpaquePointer) throws {
        let result = value.withCString { pointer in
            sqlite3_bind_text(statement, index, pointer, -1, sqliteTransient)
        }
        guard result == SQLITE_OK else {
            throw sqliteError("Cannot bind KV storage text")
        }
    }

    private func bind(_ value: Data, at index: Int32, to statement: OpaquePointer) throws {
        let result: Int32
        if value.isEmpty {
            result = sqlite3_bind_zeroblob(statement, index, 0)
        } else {
            result = value.withUnsafeBytes { bytes in
                sqlite3_bind_blob(statement, index, bytes.baseAddress, Int32(bytes.count), sqliteTransient)
            }
        }
        guard result == SQLITE_OK else {
            throw sqliteError("Cannot bind KV storage data")
        }
    }

    private func sqliteError(_ prefix: String) -> ErrorMsg {
        guard let database else {
            return ErrorMsg(errorDescription: prefix)
        }
        return ErrorMsg(errorDescription: "\(prefix): \(String(cString: sqlite3_errmsg(database)))")
    }
}
