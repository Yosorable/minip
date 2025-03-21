//
//  SQLite.swift
//  minip
//
//  Created by LZY on 2025/3/21.
//

import Foundation
import SQLite3

// TODO: support blob, release statement when errors occur
class SQLiteDBManager {
    let SQLITE_TRANSIENT = unsafeBitCast(OpaquePointer(bitPattern: -1), to: sqlite3_destructor_type.self)

    static let shared = SQLiteDBManager()
    var counter = 0

    var pathToDBKey: [String: Int] = [:]
    var dbMap: [Int: OpaquePointer] = [:]

    var stmtMap: [Int: OpaquePointer] = [:]

    func clear() {
        counter = 0
        pathToDBKey.removeAll()
        stmtMap.forEach { sqlite3_finalize($1) }
        stmtMap.removeAll()
        dbMap.forEach { sqlite3_close($1) }
        dbMap.removeAll()
    }

    func openDB(path: String) throws -> openDBResult {
        if let key = pathToDBKey[path], dbMap[key] != nil {
            return openDBResult(dbKey: key)
        } else {
            var db: OpaquePointer?
            if sqlite3_open(path, &db) == SQLITE_OK, let db = db {
                let key = counter
                counter += 1
                pathToDBKey[path] = key
                dbMap[key] = db
                return openDBResult(dbKey: key)
            } else {
                var msg = "unknown error"
                if let errorMessage = sqlite3_errmsg(db) {
                    msg = String(cString: errorMessage)
                }
                logger.error("[SQLiteDBManager] cannot open sqlite db at \(path), \(msg)")
                throw ErrorMsg(errorDescription: msg)
            }
        }
    }

    func closeDB(dbKey: Int) {
        if let db = dbMap[dbKey] {
            sqlite3_close(db)
        }
    }

    func prepareStmt(dbKey: Int, sql: String) throws -> prepareResult {
        guard let db = dbMap[dbKey] else {
            throw ErrorMsg(errorDescription: "db not opened")
        }
        var stmt: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt = stmt {
            let key = counter
            counter += 1
            stmtMap[key] = stmt
            let reader = sqlite3_stmt_readonly(stmt) != 0

            return prepareResult(stmtKey: key, reader: reader)
        }

        var msg = "unknown error"
        if let errorMessage = sqlite3_errmsg(db) {
            msg = String(cString: errorMessage)
        }
        var sqlMsg = sql
        if sqlMsg.count >= 20 {
            sqlMsg = String(sqlMsg.prefix(17)) + "..."
        }
        logger.error("[SQLiteDBManager] cannot open prepare sql (\(sqlMsg), \(msg)")
        throw ErrorMsg(errorDescription: msg)
    }

    func allStmt(dbKey: Int, stmtKey: Int, parameters: [Any]) throws -> [[String: Any]] {
        guard let _ = dbMap[dbKey], let stmt = stmtMap[stmtKey] else {
            throw ErrorMsg(errorDescription: "cannot find this statement")
        }

        defer {
            sqlite3_finalize(stmt)
            stmtMap.removeValue(forKey: stmtKey)
        }

        if sqlite3_bind_parameter_count(stmt) != parameters.count {
            throw ErrorMsg(errorDescription: "parameters not match")
        }

        for (index, param) in parameters.enumerated() {
            let position = Int32(index + 1)
            if let intParam = param as? Int64 {
                sqlite3_bind_int64(stmt, position, intParam)
            } else if let doubleParam = param as? Double {
                sqlite3_bind_double(stmt, position, doubleParam)
            } else if let stringParam = param as? String {
                sqlite3_bind_text(stmt, position, stringParam, -1, SQLITE_TRANSIENT)
            } else if param is NSNull {
                sqlite3_bind_null(stmt, position)
            }
        }

        var result: [[String: Any]] = []
        let columnCount = sqlite3_column_count(stmt)

        while sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]

            for i in 0 ..< columnCount {
                let columnName = String(cString: sqlite3_column_name(stmt, i))
                let columnType = sqlite3_column_type(stmt, i)

                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(stmt, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    row[columnName] = String(cString: sqlite3_column_text(stmt, i))
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    logger.error("[SQLiteDBManager] unsupported sqlite type")
                }
            }
            result.append(row)
        }

        return result
    }

    func runStmt(dbKey: Int, stmtKey: Int, parameters: [Any]) throws -> runStmtResult {
        guard let stmt = stmtMap[stmtKey], let db = dbMap[dbKey] else {
            throw ErrorMsg(errorDescription: "cannot find db or statement")
        }

        defer {
            sqlite3_finalize(stmt)
            stmtMap.removeValue(forKey: stmtKey)
        }

        if sqlite3_bind_parameter_count(stmt) != parameters.count {
            throw ErrorMsg(errorDescription: "parameters not match")
        }

        for (index, param) in parameters.enumerated() {
            let position = Int32(index + 1)
            if let intParam = param as? Int64 {
                sqlite3_bind_int64(stmt, position, intParam)
            } else if let doubleParam = param as? Double {
                sqlite3_bind_double(stmt, position, doubleParam)
            } else if let stringParam = param as? String {
                sqlite3_bind_text(stmt, position, stringParam, -1, SQLITE_TRANSIENT)
            } else if param is NSNull {
                sqlite3_bind_null(stmt, position)
            } else {
                throw ErrorMsg(errorDescription: "unsupported type")
            }
        }

        var affectedRows: Int
        var lastInsertRowID: Int
        if sqlite3_step(stmt) == SQLITE_DONE {
            affectedRows = Int(sqlite3_changes(db))
            lastInsertRowID = Int(sqlite3_last_insert_rowid(db))
        } else {
            let msg = String(cString: sqlite3_errmsg(db))
            logger.error("[SQLiteDBManager] run sql error: \(msg)")
            throw ErrorMsg(errorDescription: msg)
        }

        return runStmtResult(changes: affectedRows, lastInsertRowid: lastInsertRowID)
    }

    // MARK: Stream Query

    func iterateStmt(dbKey: Int, stmtKey: Int, parameters: [Any]) throws {
        guard let _ = dbMap[dbKey], let stmt = stmtMap[stmtKey] else {
            throw ErrorMsg(errorDescription: "cannot find this statement")
        }

        if sqlite3_bind_parameter_count(stmt) != parameters.count {
            sqlite3_finalize(stmt)
            stmtMap.removeValue(forKey: stmtKey)
            throw ErrorMsg(errorDescription: "parameters not match")
        }

        for (index, param) in parameters.enumerated() {
            let position = Int32(index + 1)
            if let intParam = param as? Int64 {
                sqlite3_bind_int64(stmt, position, intParam)
            } else if let doubleParam = param as? Double {
                sqlite3_bind_double(stmt, position, doubleParam)
            } else if let stringParam = param as? String {
                sqlite3_bind_text(stmt, position, stringParam, -1, SQLITE_TRANSIENT)
            } else if param is NSNull {
                sqlite3_bind_null(stmt, position)
            }
        }
    }

    func iterateStmtNext(dbKey: Int, stmtKey: Int) throws -> [String: Any]? {
        guard let _ = dbMap[dbKey], let stmt = stmtMap[stmtKey] else {
            throw ErrorMsg(errorDescription: "cannot find this statement")
        }
        let columnCount = sqlite3_column_count(stmt)

        if sqlite3_step(stmt) == SQLITE_ROW {
            var row: [String: Any] = [:]

            for i in 0 ..< columnCount {
                let columnName = String(cString: sqlite3_column_name(stmt, i))
                let columnType = sqlite3_column_type(stmt, i)

                switch columnType {
                case SQLITE_INTEGER:
                    row[columnName] = sqlite3_column_int64(stmt, i)
                case SQLITE_FLOAT:
                    row[columnName] = sqlite3_column_double(stmt, i)
                case SQLITE_TEXT:
                    row[columnName] = String(cString: sqlite3_column_text(stmt, i))
                case SQLITE_NULL:
                    row[columnName] = NSNull()
                default:
                    logger.error("[SQLiteDBManager] unsupported sqlite type")
                }
            }
            return row
        }

        sqlite3_finalize(stmt)
        stmtMap.removeValue(forKey: stmtKey)
        return nil
    }

    func iterateStmtRelease(dbKey: Int, stmtKey: Int) throws {
        guard let _ = dbMap[dbKey], let stmt = stmtMap[stmtKey] else {
            throw ErrorMsg(errorDescription: "already released")
        }

        sqlite3_finalize(stmt)
        stmtMap.removeValue(forKey: stmtKey)
    }

    // MARK: execute

    func execute(dbKey: Int, sql: String, parameters: [Any]) throws -> (reader: Bool, runRes: runStmtResult?, entityData: [[String: Any]]?) {
        let prepareRes = try prepareStmt(dbKey: dbKey, sql: sql)
        var runRes: runStmtResult?
        var entityData: [[String: Any]]?
        if prepareRes.reader {
            entityData = try allStmt(dbKey: dbKey, stmtKey: prepareRes.stmtKey, parameters: parameters)
        } else {
            runRes = try runStmt(dbKey: dbKey, stmtKey: prepareRes.stmtKey, parameters: parameters)
        }
        return (prepareRes.reader, runRes, entityData)
    }
}

extension SQLiteDBManager {
    struct openDBResult: Codable {
        var dbKey: Int
    }

    struct prepareResult: Codable {
        var stmtKey: Int
        var reader: Bool
    }

    struct runStmtResult: Codable {
        var changes: Int
        var lastInsertRowid: Int
    }
}
