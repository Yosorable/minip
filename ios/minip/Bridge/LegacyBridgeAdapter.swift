import Foundation

// LEGACY_BRIDGE_COMPAT: Temporary SDK 1.x JSON/Base64 adapter. Delete this file
// and the other marked integration points when the compatibility window ends.
// Keep legacy wire rules here; SDK 2 continues to use BridgeCodec directly.
enum LegacyBridgeAdapter {
    static let handlerName = "MinipNativeInteraction"

    struct Request {
        let api: String
        let data: [String: BridgeValue]
        let supportsPrompt: Bool
    }

    // LEGACY_BRIDGE_COMPAT: Only these old API names had a Sync suffix and were
    // allowed through prompt. Do not enable synchronous permission-gated APIs.
    private static let synchronousAPIs: Set<String> = [
        "getDeviceInfo", "getKVStorage", "setKVStorage", "deleteKVStorage", "clearKVStorage",
        "fsAccess", "fsMkdir", "fsReaddir", "fsRmdir", "fsReadFile", "fsWriteFile",
        "fsAppendFile", "fsCopyFile", "fsUnlink", "fsRename", "fsStat", "fsTruncate",
        "fsRm", "fsCp", "fsOpen", "fsClose", "fsFstat", "fsFtruncate", "fsRead", "fsWrite",
    ]

    // LEGACY_BRIDGE_COMPAT: Valid V2 requests start with a MessagePack map marker.
    // Recognize JSON objects before decoding prompt requests; never retry a failed
    // V2 decode as JSON, which could disguise malformed V2 packets.
    static func recognizesPrompt(_ text: String) -> Bool {
        text.utf8.first { ![UInt8(0x20), 0x09, 0x0a, 0x0d].contains($0) } == 0x7b
    }

    // LEGACY_BRIDGE_COMPAT: JSONDecoder preserves booleans, numbers, nulls and
    // nested objects in BridgeValue. Only filesystem byte fields use Base64.
    static func decodeRequest(_ text: String) throws -> Request {
        do {
            let value = try JSONDecoder().decode(BridgeValue.self, from: Data(text.utf8))
            guard case .object(let object) = value,
                  case .string(let originalAPI) = object["api"], !originalAPI.isEmpty else {
                throw MinipError.invalidArgument("api")
            }
            let supportsPrompt = originalAPI.hasSuffix("Sync")
            let api = supportsPrompt ? String(originalAPI.dropLast(4)) : originalAPI
            if supportsPrompt && !synchronousAPIs.contains(api) {
                throw MinipError(.apiNotFound, "Unknown API: \(originalAPI)")
            }
            var data: [String: BridgeValue]
            switch object["data"] {
            case nil, .null: data = [:]
            case .object(let parameters): data = parameters
            default: throw MinipError.invalidArgument("data")
            }
            if ["fsWriteFile", "fsAppendFile", "fsWrite"].contains(api) {
                guard case .string(let base64) = data["data"], let bytes = Data(base64Encoded: base64) else {
                    throw MinipError.invalidArgument("data")
                }
                data["data"] = .bytes(bytes)
            }
            // LEGACY_BRIDGE_COMPAT: Older HUD callers used label/subTitle and
            // case-insensitive type names. Preserve those aliases only here.
            if api == "showHUD" {
                if case .string(let type) = data["type"] {
                    let normalized = type.lowercased()
                    data["type"] = .string(normalized == "label" ? "banner" : normalized)
                }
                if case .string(let subtitle) = data["subTitle"] { data["message"] = .string(subtitle) }
            }
            // LEGACY_BRIDGE_COMPAT: Old optional numeric/bool casts treated
            // explicit null as absent and selected the API's default value.
            for key in ["recursive", "mode", "position", "delta", "interaction"] {
                if case .null = data[key] { data.removeValue(forKey: key) }
            }
            // LEGACY_BRIDGE_COMPAT: Old SQLite calls defaulted missing/null
            // bindings to an empty parameter list.
            if ["sqliteExecute", "sqliteStatementAll", "sqliteStatementRun", "sqliteCreateIterator"].contains(api) {
                switch data["parameters"] {
                case nil, .null: data["parameters"] = .array([])
                default: break
                }
            }
            return Request(api: api, data: data, supportsPrompt: supportsPrompt)
        } catch {
            if let error = error as? MinipError { throw error }
            throw MinipError(.invalidArgument, "Invalid legacy bridge request")
        }
    }

    // LEGACY_BRIDGE_COMPAT: SDK 1 expects numeric status codes and msg, and its
    // wrappers still unwrap data themselves. JSONEncoder encodes native Data as
    // Base64, including empty buffers, without sending it through MessagePack.
    static func encode(_ result: Result<BridgePayload?, Error>, for request: Request? = nil) -> String {
        do {
            let reply: Reply
            switch result {
            case .failure(let error):
                reply = Reply(code: 7, msg: MinipError.wrapping(error).message, data: nil)
            case .success(let payload):
                var data = payload
                var message: String?
                switch request?.api {
                case "fsAccess": data = BridgePayload(true)
                case "sqliteOpenDB":
                    if let payload { data = BridgePayload(DatabaseHandle(dbKey: payload)) }
                case "ping":
                    if case .string(let text) = request?.data["data"] { data = BridgePayload(text) }
                    else { data = nil }
                case "getClipboardData", "sqliteIteratorNext", "showPicker", "scanQRCode", "showAlert":
                    // LEGACY_BRIDGE_COMPAT: These APIs omitted data on missing
                    // values/cancellation. KV and memory reads keep explicit null.
                    if let payload, try JSONEncoder().encode(payload) == Data("null".utf8) {
                        data = nil
                        if ["showPicker", "scanQRCode", "showAlert"].contains(request?.api ?? "") { message = "Canceled" }
                    }
                default: break
                }
                reply = Reply(code: 0, msg: message, data: data)
            }
            return String(decoding: try JSONEncoder().encode(reply), as: UTF8.self)
        } catch {
            // LEGACY_BRIDGE_COMPAT: Even an encoding failure must settle old
            // SDK promises with a parseable legacy error envelope.
            return #"{"code":7,"msg":"Could not encode the bridge response"}"#
        }
    }

    private struct Reply: Encodable {
        let code: Int
        let msg: String?
        let data: BridgePayload?
    }

    // LEGACY_BRIDGE_COMPAT: sqliteOpenDB returned { dbKey } before SDK 2.
    private struct DatabaseHandle: Encodable { let dbKey: BridgePayload }
}
