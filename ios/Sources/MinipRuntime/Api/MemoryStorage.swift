//
//  Sync.swift
//  minip
//
//  Created by LZY on 2025/3/21.
//

import Foundation

extension MinipApi {
    func setMemoryStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let key = data["key"] as? String, let value = data["value"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        MiniAppManager.shared.appMemoryStorage[key] = value
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func setMemoryStorageIfNotExist(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let key = data["key"] as? String, let value = data["value"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        if MiniAppManager.shared.appMemoryStorage[key] == nil {
            MiniAppManager.shared.appMemoryStorage[key] = value
            replyHandler(InteropUtils.succeedWithData(data: true).toJsonString(), nil)
        } else {
            replyHandler(InteropUtils.succeedWithData(data: false).toJsonString(), nil)
        }
    }

    func getMemoryStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let key = data["key"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }

        let value = MiniAppManager.shared.appMemoryStorage[key]
        replyHandler(InteropUtils.succeedWithData(data: value).toJsonString(), nil)
    }

    func removeMemoryStorage(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        guard let data = param.data as? [String: Any], let key = data["key"] as? String else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        MiniAppManager.shared.appMemoryStorage.removeValue(forKey: key)
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func clearMemoryCache(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = MiniAppManager.shared.openedApp?.appId else {
            replyHandler(InteropUtils.fail(msg: "Error").toJsonString(), nil)
            return
        }
        MiniAppManager.shared.appMemoryStorage.removeAll()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }
}
