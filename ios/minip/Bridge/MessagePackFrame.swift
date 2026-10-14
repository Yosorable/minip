import Foundation

/// Validate framing before handing bytes to the upstream decoder's unchecked
/// buffer reader. Binary payloads are skipped in one step, without copying.
enum MessagePackFrame {
    static func validate(_ data: Data) throws {
        try data.withUnsafeBytes { raw in
            var cursor = Cursor(bytes: raw.bindMemory(to: UInt8.self))
            try cursor.value(depth: 0)
            guard cursor.offset == raw.count else { throw malformed() }
        }
    }

    private static func malformed() -> MinipError {
        MinipError(.invalidArgument, "Malformed MessagePack request")
    }

    private struct Cursor {
        let bytes: UnsafeBufferPointer<UInt8>
        var offset = 0
        var remaining: Int { bytes.count - offset }

        mutating func byte() throws -> UInt8 {
            guard remaining > 0 else { throw malformed() }
            defer { offset += 1 }
            return bytes[offset]
        }

        mutating func integer(_ width: Int) throws -> Int {
            guard remaining >= width else { throw malformed() }
            var result = 0
            for _ in 0..<width { result = (result << 8) | Int(try byte()) }
            return result
        }

        mutating func skip(_ length: Int) throws {
            guard length >= 0, length <= remaining else { throw malformed() }
            offset += length
        }

        mutating func text(_ length: Int) throws {
            let start = offset
            try skip(length)
            guard String(bytes: bytes[start..<offset], encoding: .utf8) != nil else { throw malformed() }
        }

        mutating func collection(_ count: Int, depth: Int) throws {
            guard count <= remaining else { throw malformed() }
            for _ in 0..<count { try value(depth: depth + 1) }
        }

        mutating func value(depth: Int) throws {
            guard depth <= 100 else { throw malformed() }
            let marker = try byte()
            switch marker {
            case 0x00...0x7f, 0xe0...0xff, 0xc0, 0xc2, 0xc3: break
            case 0x80...0x8f: try collection(Int(marker & 15) * 2, depth: depth)
            case 0x90...0x9f: try collection(Int(marker & 15), depth: depth)
            case 0xa0...0xbf: try text(Int(marker & 31))
            case 0xc4: try skip(integer(1))
            case 0xc5: try skip(integer(2))
            case 0xc6: try skip(integer(4))
            case 0xca: try skip(4)
            case 0xcb: try skip(8)
            case 0xcc, 0xd0: try skip(1)
            case 0xcd, 0xd1: try skip(2)
            case 0xce, 0xd2: try skip(4)
            case 0xcf, 0xd3: try skip(8)
            case 0xd9: try text(integer(1))
            case 0xda: try text(integer(2))
            case 0xdb: try text(integer(4))
            case 0xdc: try collection(integer(2), depth: depth)
            case 0xdd: try collection(integer(4), depth: depth)
            case 0xde: try collection(integer(2) * 2, depth: depth)
            case 0xdf: try collection(integer(4) * 2, depth: depth)
            default:
                // The bridge accepts the standard value types, not extensions.
                throw malformed()
            }
        }
    }
}
