//
//  SQLite.swift
//  minip
//
//  Created by LZY on 2025/3/21.
//

import Foundation

extension MinipApi {
    func sqliteOpenDB(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let path = data["path"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let appHomeURL = Global.shared.projectDataFolderURL.appending(component: appId, directoryHint: .isDirectory)
        let dbFileURL = appHomeURL.appending(component: path, directoryHint: .notDirectory).standardizedFileURL
        let dbFolderURL = dbFileURL.deletingLastPathComponent()
        if !dbFolderURL.path.contains(appHomeURL.path) {
            replyHandler(InteropUtils.fail(msg: "Cannot access this file").toJsonString(), nil)
            return
        }

        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: dbFolderURL.path) {
                try fileManager.createDirectory(at: dbFolderURL, withIntermediateDirectories: true)
            }
            let res = try SQLiteDBManager.shared.openDB(path: dbFileURL.path)
            replyHandler(InteropUtils.succeedWithData(data: res).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteCloseDB(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let dbKey = data["dbKey"] as? Int else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        SQLiteDBManager.shared.closeDB(dbKey: dbKey)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func sqlitePrepare(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let dbKey = data["dbKey"] as? Int, let sql = data["sql"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            let res = try SQLiteDBManager.shared.prepareStmt(dbKey: dbKey, sql: sql)
            replyHandler(InteropUtils.succeedWithData(data: res).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteStatementAll(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let stmtKey = data["stmtKey"] as? Int
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let parameters = (data["parameters"] as? [Any]) ?? []

        do {
            let res = try SQLiteDBManager.shared.allStmt(dbKey: dbKey, stmtKey: stmtKey, parameters: parameters)
            let replyRes: [String: Any] = [
                "code": InteropUtils.successCode,
                "data": res
            ]
            let jsonData = try JSONSerialization.data(withJSONObject: replyRes)

            if let jsonString = String(data: jsonData, encoding: .utf8) {
                replyHandler(jsonString, nil)
            } else {
                throw ErrorMsg(errorDescription: "Internal Error")
            }
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteStatementRun(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let stmtKey = data["stmtKey"] as? Int
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let parameters = (data["parameters"] as? [Any]) ?? []

        do {
            let res = try SQLiteDBManager.shared.runStmt(dbKey: dbKey, stmtKey: stmtKey, parameters: parameters)

            replyHandler(InteropUtils.succeedWithData(data: res).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteExecute(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let sql = data["sql"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let parameters = (data["parameters"] as? [Any]) ?? []

        do {
            let (reader, runRes, entityData) = try SQLiteDBManager.shared.execute(dbKey: dbKey, sql: sql, parameters: parameters)
            var res = [String: Any]()
            res["reader"] = reader
            if let runRes = runRes {
                res["runRes"] = [
                    "changes": runRes.changes,
                    "lastInsertRowid": runRes.lastInsertRowid
                ]
            }
            res["entityData"] = entityData

            let replyRes: [String: Any] = [
                "code": InteropUtils.successCode,
                "data": res
            ]

            if (reader && entityData != nil) || (!reader && runRes != nil) {
                let jsonData = try JSONSerialization.data(withJSONObject: replyRes)

                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    replyHandler(jsonString, nil)
                    return
                }
            } else {
                throw ErrorMsg(errorDescription: "Internal Error")
            }
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    // MARK: Stream Query

    func sqliteCreateIterator(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let stmtKey = data["stmtKey"] as? Int
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let parameters = (data["parameters"] as? [Any]) ?? []

        do {
            try SQLiteDBManager.shared.iterateStmt(dbKey: dbKey, stmtKey: stmtKey, parameters: parameters)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteIteratorNext(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let stmtKey = data["stmtKey"] as? Int
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            let res = try SQLiteDBManager.shared.iterateStmtNext(dbKey: dbKey, stmtKey: stmtKey)
            if let res = res {
                let replyRes: [String: Any] = [
                    "code": InteropUtils.successCode,
                    "data": res
                ]
                let jsonData = try JSONSerialization.data(withJSONObject: replyRes)

                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    replyHandler(jsonString, nil)
                } else {
                    throw ErrorMsg(errorDescription: "Internal Error")
                }
            } else {
                replyHandler(InteropUtils.succeed().toJsonString(), nil)
            }
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func sqliteIteratorRelease(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard
            let data = param.data as? [String: Any],
            let dbKey = data["dbKey"] as? Int,
            let stmtKey = data["stmtKey"] as? Int
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            try SQLiteDBManager.shared.iterateStmtRelease(dbKey: dbKey, stmtKey: stmtKey)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }
}
