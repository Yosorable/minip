import Foundation
import SQLite3

final class SQLiteDBManager {
    static let shared = SQLiteDBManager()
    private let transient = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)
    private var counter = 0
    private var pathToDBKey: [String: Int] = [:]
    private var dbMap: [Int: OpaquePointer] = [:]
    private var stmtMap: [Int: OpaquePointer] = [:]
    private var stmtToDBKey: [Int: Int] = [:]
    private var iterators: Set<Int> = []

    func clear() {
        for statement in stmtMap.values { sqlite3_finalize(statement) }
        for database in dbMap.values { sqlite3_close(database) }
        stmtMap.removeAll()
        stmtToDBKey.removeAll()
        iterators.removeAll()
        dbMap.removeAll()
        pathToDBKey.removeAll()
    }

    private func database(_ key: Int) throws -> OpaquePointer {
        guard let database = dbMap[key] else { throw MinipError(.invalidState, "Database is not open") }
        return database
    }

    private func statement(dbKey: Int, stmtKey: Int) throws -> OpaquePointer {
        _ = try database(dbKey)
        guard stmtToDBKey[stmtKey] == dbKey, let statement = stmtMap[stmtKey] else {
            throw MinipError(.invalidState, "Statement is not open in this database")
        }
        return statement
    }

    private func error(_ database: OpaquePointer?) -> MinipError {
        MinipError(.databaseError, String(cString: sqlite3_errmsg(database)), details: [
            "sqliteCode": .signed(Int64(sqlite3_extended_errcode(database))),
        ])
    }

    private func release(_ key: Int) {
        if let statement = stmtMap.removeValue(forKey: key) { sqlite3_finalize(statement) }
        stmtToDBKey.removeValue(forKey: key)
        iterators.remove(key)
    }

    func openDB(path: String) throws -> openDBResult {
        if let key = pathToDBKey[path], dbMap[key] != nil { return openDBResult(dbKey: key) }
        var pointer: OpaquePointer?
        guard sqlite3_open(path, &pointer) == SQLITE_OK, let database = pointer else {
            let failure = error(pointer)
            if let pointer { sqlite3_close(pointer) }
            throw failure
        }
        let key = counter
        counter += 1
        dbMap[key] = database
        pathToDBKey[path] = key
        return openDBResult(dbKey: key)
    }

    func closeDB(dbKey: Int) throws {
        let database = try database(dbKey)
        for key in stmtToDBKey.filter({ $0.value == dbKey }).map(\.key) { release(key) }
        guard sqlite3_close(database) == SQLITE_OK else { throw error(database) }
        dbMap.removeValue(forKey: dbKey)
        pathToDBKey = pathToDBKey.filter { $0.value != dbKey }
    }

    func prepareStmt(dbKey: Int, sql: String) throws -> prepareResult {
        let database = try database(dbKey)
        guard !sql.utf8.contains(0) else { throw MinipError.invalidArgument("sql") }
        var pointer: OpaquePointer?
        guard sqlite3_prepare_v2(database, sql, -1, &pointer, nil) == SQLITE_OK else {
            if let pointer { sqlite3_finalize(pointer) }
            throw error(database)
        }
        guard let statement = pointer else { throw MinipError.invalidArgument("sql") }
        let key = counter
        counter += 1
        stmtMap[key] = statement
        stmtToDBKey[key] = dbKey
        return prepareResult(stmtKey: key, reader: sqlite3_column_count(statement) > 0)
    }

    private func bind(_ parameters: [BridgeValue], to statement: OpaquePointer) throws {
        guard sqlite3_bind_parameter_count(statement) == parameters.count else {
            throw MinipError(.invalidArgument, "SQLite parameter count does not match", details: ["parameter": .string("parameters")])
        }
        for (index, parameter) in parameters.enumerated() {
            let position = Int32(index + 1)
            let status: Int32
            switch parameter {
            case .null: status = sqlite3_bind_null(statement, position)
            case .bool(let value): status = sqlite3_bind_int(statement, position, value ? 1 : 0)
            case .signed(let value): status = sqlite3_bind_int64(statement, position, value)
            case .unsigned(let value):
                guard let signed = Int64(exactly: value) else { throw MinipError(.invalidArgument, "SQLite integers must fit Int64") }
                status = sqlite3_bind_int64(statement, position, signed)
            case .number(let value):
                guard value.isFinite else { throw MinipError.invalidArgument("parameters") }
                status = sqlite3_bind_double(statement, position, value)
            case .string(let value):
                guard let count = Int32(exactly: value.utf8.count) else { throw MinipError.invalidArgument("parameters") }
                status = value.withCString { sqlite3_bind_text(statement, position, $0, count, transient) }
            case .bytes(let value):
                guard let count = Int32(exactly: value.count) else { throw MinipError.invalidArgument("parameters") }
                if value.isEmpty {
                    status = sqlite3_bind_zeroblob(statement, position, 0)
                } else {
                    status = value.withUnsafeBytes { sqlite3_bind_blob(statement, position, $0.baseAddress, count, transient) }
                }
            case .array, .object:
                throw MinipError(.invalidArgument, "Unsupported SQLite parameter type")
            }
            guard status == SQLITE_OK else { throw error(sqlite3_db_handle(statement)) }
        }
    }

    private func row(_ statement: OpaquePointer) throws -> [String: BridgeValue] {
        var result: [String: BridgeValue] = [:]
        for column in 0..<sqlite3_column_count(statement) {
            let name = String(cString: sqlite3_column_name(statement, column))
            switch sqlite3_column_type(statement, column) {
            case SQLITE_INTEGER: result[name] = .signed(sqlite3_column_int64(statement, column))
            case SQLITE_FLOAT: result[name] = .number(sqlite3_column_double(statement, column))
            case SQLITE_TEXT:
                let count = Int(sqlite3_column_bytes(statement, column))
                let text = sqlite3_column_text(statement, column)
                let bytes = UnsafeBufferPointer(start: text, count: count)
                guard let value = String(bytes: bytes, encoding: .utf8) else { throw MinipError(.databaseError, "SQLite text is not valid UTF-8") }
                result[name] = .string(value)
            case SQLITE_BLOB:
                let count = Int(sqlite3_column_bytes(statement, column))
                let value = sqlite3_column_blob(statement, column)
                result[name] = .bytes(count == 0 ? Data() : Data(bytes: value!, count: count))
            case SQLITE_NULL: result[name] = .null
            default: throw MinipError(.databaseError, "Unsupported SQLite result type")
            }
        }
        return result
    }

    func allStmt(dbKey: Int, stmtKey: Int, parameters: [BridgeValue]) throws -> [[String: BridgeValue]] {
        let statement = try statement(dbKey: dbKey, stmtKey: stmtKey)
        guard !iterators.contains(stmtKey) else { throw MinipError(.invalidState, "Statement already has an active iterator") }
        defer { release(stmtKey) }
        try bind(parameters, to: statement)
        var result: [[String: BridgeValue]] = []
        while true {
            switch sqlite3_step(statement) {
            case SQLITE_ROW: result.append(try row(statement))
            case SQLITE_DONE: return result
            default: throw error(sqlite3_db_handle(statement))
            }
        }
    }

    func runStmt(dbKey: Int, stmtKey: Int, parameters: [BridgeValue]) throws -> runStmtResult {
        let statement = try statement(dbKey: dbKey, stmtKey: stmtKey)
        guard !iterators.contains(stmtKey) else { throw MinipError(.invalidState, "Statement already has an active iterator") }
        defer { release(stmtKey) }
        guard sqlite3_column_count(statement) == 0 else { throw MinipError(.invalidArgument, "Use a query API for statements that return rows") }
        try bind(parameters, to: statement)
        guard sqlite3_step(statement) == SQLITE_DONE else { throw error(sqlite3_db_handle(statement)) }
        let database = try database(dbKey)
        return runStmtResult(changes: Int(sqlite3_changes(database)), lastInsertRowid: sqlite3_last_insert_rowid(database))
    }

    func iterateStmt(dbKey: Int, stmtKey: Int, parameters: [BridgeValue]) throws {
        let statement = try statement(dbKey: dbKey, stmtKey: stmtKey)
        guard !iterators.contains(stmtKey) else { throw MinipError(.invalidState, "Iterator is already active") }
        do {
            try bind(parameters, to: statement)
            iterators.insert(stmtKey)
        } catch {
            release(stmtKey)
            throw error
        }
    }

    func iterateStmtNext(dbKey: Int, stmtKey: Int) throws -> [String: BridgeValue]? {
        let statement = try statement(dbKey: dbKey, stmtKey: stmtKey)
        guard iterators.contains(stmtKey) else { throw MinipError(.invalidState, "Iterator is not active") }
        do {
            switch sqlite3_step(statement) {
            case SQLITE_ROW: return try row(statement)
            case SQLITE_DONE: release(stmtKey); return nil
            default: throw error(sqlite3_db_handle(statement))
            }
        } catch {
            release(stmtKey)
            throw error
        }
    }

    func iterateStmtRelease(dbKey: Int, stmtKey: Int) throws {
        _ = try database(dbKey)
        guard stmtMap[stmtKey] != nil else { return }
        _ = try statement(dbKey: dbKey, stmtKey: stmtKey)
        release(stmtKey)
    }

    func execute(dbKey: Int, sql: String, parameters: [BridgeValue]) throws -> (reader: Bool, runRes: runStmtResult?, entityData: [[String: BridgeValue]]?) {
        let prepared = try prepareStmt(dbKey: dbKey, sql: sql)
        if prepared.reader {
            return (true, nil, try allStmt(dbKey: dbKey, stmtKey: prepared.stmtKey, parameters: parameters))
        }
        return (false, try runStmt(dbKey: dbKey, stmtKey: prepared.stmtKey, parameters: parameters), nil)
    }

    struct openDBResult: Codable { let dbKey: Int }
    struct prepareResult: Codable { let stmtKey: Int; let reader: Bool }
    struct runStmtResult: Codable { let changes: Int; let lastInsertRowid: Int64 }
}
