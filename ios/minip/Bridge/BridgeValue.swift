import Foundation

indirect enum BridgeValue: Codable {
    case null
    case bool(Bool)
    case signed(Int64)
    case unsigned(UInt64)
    case number(Double)
    case string(String)
    case bytes(Data)
    case array([BridgeValue])
    case object([String: BridgeValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() { self = .null }
        else if let value = try? container.decode(Bool.self) { self = .bool(value) }
        else if let value = try? container.decode(UInt64.self) { self = .unsigned(value) }
        else if let value = try? container.decode(Int64.self) { self = .signed(value) }
        else if let value = try? container.decode(Double.self) {
            guard value.isFinite else { throw MinipError(.invalidArgument, "Numbers must be finite") }
            self = .number(value)
        }
        else if let value = try? container.decode(String.self) { self = .string(value) }
        else if let value = try? container.decode(Data.self) { self = .bytes(value) }
        else if let value = try? container.decode([BridgeValue].self) { self = .array(value) }
        else { self = .object(try container.decode([String: BridgeValue].self)) }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null: try container.encodeNil()
        case .bool(let value): try container.encode(value)
        case .signed(let value): try container.encode(value)
        case .unsigned(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .string(let value): try container.encode(value)
        case .bytes(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }

    var int64: Int64? {
        switch self {
        case .signed(let value): return value
        case .unsigned(let value): return Int64(exactly: value)
        case .number(let value): return Int64(exactly: value)
        default: return nil
        }
    }

    var double: Double? {
        switch self {
        case .signed(let value): return Double(value)
        case .unsigned(let value): return Double(value)
        case .number(let value): return value
        default: return nil
        }
    }

}

/// Type erasure must use the container API so Data keeps MessagePack's bin type.
struct BridgePayload: Encodable {
    private let write: (Encoder) throws -> Void

    init<T: Encodable>(_ value: T) {
        write = { encoder in
            var container = encoder.singleValueContainer()
            try container.encode(value)
        }
    }

    func encode(to encoder: Encoder) throws { try write(encoder) }
}

struct BridgeRequest {
    let api: String
    let data: [String: BridgeValue]?
}

struct BridgeReply: Encodable {
    let ok: Bool
    let data: BridgePayload?
    let error: MinipError?

    static func success(_ data: BridgePayload? = nil) -> BridgeReply {
        BridgeReply(ok: true, data: data, error: nil)
    }

    static func failure(_ error: Error) -> BridgeReply {
        BridgeReply(ok: false, data: nil, error: MinipError.wrapping(error))
    }
}
