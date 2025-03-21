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
        let appHomeURL = Global.shared.projectDataFolderURL.appendingPolyfill(path: appId + "/")
        let dbFileURL = appHomeURL.appendingPolyfill(component: path).standardizedFileURL
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
}
