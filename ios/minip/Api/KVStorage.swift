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
        guard appId != KVStorageManager.privacyNamespace else {
            replyHandler(InteropUtils.fail(msg: "Invalid app id").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any],
            let key = data["key"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            let res = try KVStorageManager.shared.string(forKey: key, namespace: appId)
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
        guard appId != KVStorageManager.privacyNamespace else {
            replyHandler(InteropUtils.fail(msg: "Invalid app id").toJsonString(), nil)
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
            try KVStorageManager.shared.set(value, forKey: key, namespace: appId)
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
        guard appId != KVStorageManager.privacyNamespace else {
            replyHandler(InteropUtils.fail(msg: "Invalid app id").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any],
            let key = data["key"] as? String
        else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        do {
            try KVStorageManager.shared.deleteValue(forKey: key, namespace: appId)
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
        guard appId != KVStorageManager.privacyNamespace else {
            replyHandler(InteropUtils.fail(msg: "Invalid app id").toJsonString(), nil)
            return
        }

        do {
            try KVStorageManager.shared.clear(namespace: appId)
            replyHandler(InteropUtils.succeed().toJsonString(), nil)
        } catch {
            replyHandler(InteropUtils.fail(msg: error.localizedDescription).toJsonString(), nil)
        }
    }
}
