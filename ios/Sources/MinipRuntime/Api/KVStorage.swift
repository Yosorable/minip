//
//  KVStorage.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

extension MinipApi {
    func getKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            let res = try KVStorageManager.shared.getDB(dbName: appId)?.get(type: String.self, forKey: key)
            replyHandler(InteropUtils.succeedWithData(data: res).toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func setKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String,
              let value = data["value"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            try KVStorageManager.shared.getDB(dbName: appId)?.put(value: value, forKey: key)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func deleteKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            try KVStorageManager.shared.getDB(dbName: appId)?.deleteValue(forKey: key)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }

    func clearKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }

        do {
            try KVStorageManager.shared.getDB(dbName: appId)?.empty()
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }
}
