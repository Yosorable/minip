import Foundation

extension MinipApi {
    func getMemoryStorage(param: Parameter) throws -> String? {
        MiniAppManager.shared.appMemoryStorage[try param.string("key")]
    }

    func setMemoryStorage(param: Parameter) throws {
        MiniAppManager.shared.appMemoryStorage[try param.string("key")] = try param.string("value")
    }

    func setMemoryStorageIfNotExist(param: Parameter) throws -> Bool {
        let key = try param.string("key")
        let value = try param.string("value")
        guard MiniAppManager.shared.appMemoryStorage[key] == nil else { return false }
        MiniAppManager.shared.appMemoryStorage[key] = value
        return true
    }

    func removeMemoryStorage(param: Parameter) throws {
        MiniAppManager.shared.appMemoryStorage.removeValue(forKey: try param.string("key"))
    }

    func clearMemoryStorage() {
        MiniAppManager.shared.appMemoryStorage.removeAll()
    }
}
