//
//  KVStorage.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

extension MinipApi {
    func getKVStorageSync(param: Parameter) -> String? {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            return InteropUtils.fail(msg: "Error").toJsonString()
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String
        else {
            return InteropUtils.fail(msg: "Error parameter").toJsonString()
        }

        do {
            let res = try KVStoreManager.shared.getDB(dbName: appId)?.get(type: String.self, forKey: key)
            return InteropUtils.succeedWithData(data: res).toJsonString()
        } catch {
            return InteropUtils.fail(msg: error.localizedDescription).toJsonString()
        }
    }

    func setKVStorageSync(param: Parameter) -> String? {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            return InteropUtils.fail(msg: "Error").toJsonString()
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String,
              let value = data["value"] as? String
        else {
            return InteropUtils.fail(msg: "Error parameter").toJsonString()
        }

        do {
            try KVStoreManager.shared.getDB(dbName: appId)?.put(value: value, forKey: key)
            return InteropUtils.succeed().toJsonString()
        } catch {
            return InteropUtils.fail(msg: error.localizedDescription).toJsonString()
        }
    }

    func deleteKVStorageSync(param: Parameter) -> String? {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            return InteropUtils.fail(msg: "Error").toJsonString()
        }
        guard let data = param.data as? [String: Any],
              let key = data["key"] as? String
        else {
            return InteropUtils.fail(msg: "Error parameter").toJsonString()
        }

        do {
            try KVStoreManager.shared.getDB(dbName: appId)?.deleteValue(forKey: key)
            return InteropUtils.succeed().toJsonString()
        } catch {
            return InteropUtils.fail(msg: error.localizedDescription).toJsonString()
        }
    }

    func clearKVStorageSync(param: Parameter) -> String? {
        guard let appId = MiniAppManager.shared.openedApp?.appId else {
            return InteropUtils.fail(msg: "Error").toJsonString()
        }

        do {
            try KVStoreManager.shared.getDB(dbName: appId)?.empty()
            return InteropUtils.succeed().toJsonString()
        } catch {
            return InteropUtils.fail(msg: error.localizedDescription).toJsonString()
        }
    }

    func getKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler(getKVStorageSync(param: param), nil)
    }

    func setKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler(setKVStorageSync(param: param), nil)
    }

    func deleteKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler(deleteKVStorageSync(param: param), nil)
    }

    func clearKVStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        replyHandler(clearKVStorageSync(param: param), nil)
    }
}
