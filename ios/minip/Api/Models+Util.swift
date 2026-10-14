import Foundation

extension MinipApi {
    @MainActor
    struct Parameter {
        let webView: MWebView
        let data: [String: BridgeValue]

        var viewController: MiniPageViewController {
            get throws {
                guard let controller = webView.holderObject as? MiniPageViewController else {
                    throw MinipError(.invalidState, "The calling page is no longer available")
                }
                return controller
            }
        }

        var appID: String { get throws { try viewController.app.appId } }

        var fileSystem: FileSystemManager {
            get throws {
                guard let fileSystem = MiniAppManager.shared.getFSManager() else {
                    throw MinipError(.invalidState, "The application's file system is unavailable")
                }
                return fileSystem
            }
        }

        func value(_ key: String) throws -> BridgeValue {
            guard let value = data[key] else { throw MinipError.invalidArgument(key) }
            return value
        }

        func string(_ key: String) throws -> String {
            guard case .string(let value) = data[key] else { throw MinipError.invalidArgument(key) }
            return value
        }

        func optionalString(_ key: String) throws -> String? {
            guard let value = data[key] else { return nil }
            if case .null = value { return nil }
            guard case .string(let string) = value else { throw MinipError.invalidArgument(key) }
            return string
        }

        func int(_ key: String, default fallback: Int? = nil) throws -> Int {
            guard let value = data[key] else {
                if let fallback { return fallback }
                throw MinipError.invalidArgument(key)
            }
            guard let integer = value.int64, let result = Int(exactly: integer) else { throw MinipError.invalidArgument(key) }
            return result
        }

        func optionalInt(_ key: String) throws -> Int? {
            guard let value = data[key] else { return nil }
            if case .null = value { return nil }
            return try int(key)
        }

        func int32(_ key: String) throws -> Int32 {
            guard let value = Int32(exactly: try int(key)) else { throw MinipError.invalidArgument(key) }
            return value
        }

        func nonnegativeInt(_ key: String, default fallback: Int? = nil) throws -> Int {
            let value = try int(key, default: fallback)
            guard value >= 0 else { throw MinipError.invalidArgument(key) }
            return value
        }

        func position() throws -> Int? {
            let position = try optionalInt("position")
            guard position == nil || position! >= 0 else { throw MinipError.invalidArgument("position") }
            return position
        }

        func bool(_ key: String, default fallback: Bool = false) throws -> Bool {
            guard let value = data[key] else { return fallback }
            guard case .bool(let result) = value else { throw MinipError.invalidArgument(key) }
            return result
        }

        func number(_ key: String) throws -> Double? {
            guard let value = data[key] else { return nil }
            if case .null = value { return nil }
            guard let number = value.double, number.isFinite else { throw MinipError.invalidArgument(key) }
            return number
        }

        func bytes(_ key: String) throws -> Data {
            guard case .bytes(let value) = data[key] else { throw MinipError.invalidArgument(key) }
            return value
        }

        func array(_ key: String) throws -> [BridgeValue] {
            guard case .array(let value) = data[key] else { throw MinipError.invalidArgument(key) }
            return value
        }

        func optionalArray(_ key: String) throws -> [BridgeValue]? {
            guard let value = data[key] else { return nil }
            if case .null = value { return nil }
            return try array(key)
        }

        func strings(_ key: String) throws -> [String] {
            try array(key).map { value in
                guard case .string(let text) = value else { throw MinipError.invalidArgument(key) }
                return text
            }
        }

        func object(_ value: BridgeValue, name: String) throws -> Parameter {
            guard case .object(let data) = value else { throw MinipError.invalidArgument(name) }
            return Parameter(webView: webView, data: data)
        }

        func requirePresentation() throws -> MiniPageViewController {
            let controller = try viewController
            guard controller.viewIfLoaded?.window != nil, controller.presentedViewController == nil else {
                throw MinipError(.invalidState, "The page cannot present another view right now")
            }
            return controller
        }
    }
}
