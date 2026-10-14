import Foundation

extension MinipApi {
    private func storageNamespace(_ param: Parameter) throws -> String {
        let appID = try param.appID
        guard appID != KVStorageManager.privacyNamespace else { throw MinipError(.permissionDenied, "Reserved storage namespace") }
        return appID
    }

    func getKVStorage(param: Parameter) throws -> String? {
        try KVStorageManager.shared.string(forKey: param.string("key"), namespace: storageNamespace(param))
    }

    func setKVStorage(param: Parameter) throws {
        try KVStorageManager.shared.set(param.string("value"), forKey: param.string("key"), namespace: storageNamespace(param))
    }

    func deleteKVStorage(param: Parameter) throws {
        try KVStorageManager.shared.deleteValue(forKey: param.string("key"), namespace: storageNamespace(param))
    }

    func clearKVStorage(param: Parameter) throws {
        try KVStorageManager.shared.clear(namespace: storageNamespace(param))
    }
}
