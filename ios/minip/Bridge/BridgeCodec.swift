import CoreFoundation
import Foundation
import SwiftMsgpack

enum BridgeCodec {
    static let handlerName = "MinipNativeInteractionV2"

    static func bytes(from text: String) throws -> Data {
        let string = text as NSString
        guard string.length > 0 else { throw MinipError(.invalidArgument, "Empty bridge request") }
        var result = Data(count: string.length)
        var written = 0
        let converted = result.withUnsafeMutableBytes { buffer in
            CFStringGetBytes(string as CFString, CFRange(location: 0, length: string.length),
                             CFStringBuiltInEncodings.isoLatin1.rawValue, 0, false,
                             buffer.bindMemory(to: UInt8.self).baseAddress, buffer.count, &written)
        }
        guard converted == string.length, written == string.length else {
            throw MinipError(.invalidArgument, "Bridge strings must contain only byte-valued code units")
        }
        return result
    }

    static func string(from data: Data) -> String {
        // Construct the complete packet before crossing the String boundary.
        String(data: data, encoding: .isoLatin1)!
    }

    static func decodeRequest(_ text: String) throws -> BridgeRequest {
        do {
            let data = try bytes(from: text)
            try MessagePackFrame.validate(data)
            let value = try MsgPackDecoder().decode(BridgeValue.self, from: data)
            guard case .object(let request) = value,
                  case .string(let api) = request["api"], !api.isEmpty else {
                throw MinipError.invalidArgument("api")
            }
            let parameters: [String: BridgeValue]?
            if let value = request["data"] {
                guard case .object(let object) = value else { throw MinipError.invalidArgument("data") }
                parameters = object
            } else { parameters = nil }
            return BridgeRequest(api: api, data: parameters)
        } catch {
            if let error = error as? MinipError { throw error }
            throw MinipError(.invalidArgument, "Invalid bridge request", details: ["reason": .string(error.localizedDescription)])
        }
    }

    static func encode(_ reply: BridgeReply) throws -> String {
        string(from: try MsgPackEncoder().encode(reply))
    }

    static func encode(_ result: Result<BridgePayload?, Error>) throws -> String {
        switch result {
        case .success(let payload):
            do { return try encode(BridgeReply.success(payload)) }
            catch { return try encode(BridgeReply.failure(MinipError(.internalError, "Could not encode the API result"))) }
        case .failure(let error):
            return try encode(BridgeReply.failure(error))
        }
    }
}
