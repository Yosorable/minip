//
//  SQLite.swift
//  minip
//
//  Created by LZY on 2024/12/10.
//

import Foundation
import SQLite3

class SQLiteDatabase {
    var db: OpaquePointer?

    // 打开数据库
    func open(databasePath: String) -> Bool {
        if sqlite3_open(databasePath, &db) == SQLITE_OK {
            print("Successfully opened database at \(databasePath).")
            return true
        } else {
            print("Failed to open database.")
            return false
        }
    }

    // 关闭数据库
    func close() {
        if db != nil {
            sqlite3_close(db)
            print("Database closed.")
        }
    }

    // 执行 SQL 语句
    func executeQuery(sql: String) throws -> Any? {
        // 判断是否是查询语句
//        if sql.lowercased().hasPrefix("select") {
//            return try executeSelectQuery(sql: sql)
//        } else {
//            return try executeNonQuery(sql: sql)
//        }
        return try executeSelectQuery(sql: sql)
    }

    // 执行查询操作
    private func executeSelectQuery(sql: String) throws -> [[String: Any]]? {
        var queryStatement: OpaquePointer?
        var results: [[String: Any]] = []

        // 准备 SQL 语句
        if sqlite3_prepare_v2(db, sql, -1, &queryStatement, nil) == SQLITE_OK {
            // 遍历查询结果
            while sqlite3_step(queryStatement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columnCount = sqlite3_column_count(queryStatement)

                for columnIndex in 0 ..< columnCount {
                    let columnName = String(cString: sqlite3_column_name(queryStatement, columnIndex))
                    let columnValue: Any
                    switch sqlite3_column_type(queryStatement, columnIndex) {
                    case SQLITE_TEXT:
                        columnValue = String(cString: sqlite3_column_text(queryStatement, columnIndex))
                    case SQLITE_INTEGER:
                        columnValue = sqlite3_column_int(queryStatement, columnIndex)
                    case SQLITE_FLOAT:
                        columnValue = sqlite3_column_double(queryStatement, columnIndex)
                    case SQLITE_NULL:
                        columnValue = NSNull()
                    default:
                        columnValue = ""
                    }
                    row[columnName] = columnValue
                }
                results.append(row)
            }
        } else {
            // 释放查询语句
            sqlite3_finalize(queryStatement)
            throw ErrorMsg(errorDescription: "Failed to prepare query statement.")
        }

        // 释放查询语句
        sqlite3_finalize(queryStatement)

        return results.isEmpty ? nil : results
    }

    // 执行非查询操作（插入、更新、删除）
    private func executeNonQuery(sql: String) throws -> String {
        var errorMessage: UnsafeMutablePointer<Int8>?

        // 执行 SQL 语句
        if sqlite3_exec(db, sql, nil, nil, &errorMessage) == SQLITE_OK {
            return "Operation completed successfully."
        } else {
            let errorMsg = String(cString: errorMessage!)
            throw ErrorMsg(errorDescription: "Error: \(errorMsg)")
        }
    }

    deinit {
        close()
        logger.info("[SQLiteDatabase] instance is being deallocated and database connection is closed.")
    }
}
