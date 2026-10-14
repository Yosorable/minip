import Foundation
import WebKit

// LEGACY_BRIDGE_COMPAT: Temporary SDK 1.x entry points. Remove this file together
// with LegacyBridgeAdapter and the marked WebView registration/prompt branch.
// Both transports use MinipApi so current permissions and app isolation apply.
final class LegacyNativeInteraction: NSObject, WKScriptMessageHandlerWithReply {
    static let name = LegacyBridgeAdapter.handlerName

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        Task { @MainActor in
            var request: LegacyBridgeAdapter.Request?
            let result: Result<BridgePayload?, Error>
            do {
                guard let body = message.body as? String, let webView = message.webView as? MWebView else {
                    throw MinipError(.invalidArgument, "Expected a legacy bridge request string")
                }
                let decoded = try LegacyBridgeAdapter.decodeRequest(body)
                request = decoded
                guard let api = MinipApi.APIName(rawValue: decoded.api) else {
                    throw MinipError(.apiNotFound, "Unknown API: \(decoded.api)")
                }
                let parameter = MinipApi.Parameter(webView: webView, data: decoded.data)
                try Self.prepareLegacyDatabaseDirectory(decoded, webView: webView)
                result = .success(try await MinipApi.shared.call(apiName: api, param: parameter))
            } catch { result = .failure(error) }
            replyHandler(LegacyBridgeAdapter.encode(result, for: request), nil)
        }
    }

    // LEGACY_BRIDGE_COMPAT: Keep legacy sync decoding and JSON replies outside
    // the V2 prompt path. The old sync allowlist excludes permission prompts.
    @MainActor
    static func handlePrompt(_ prompt: String, webView: WKWebView) -> String {
        var request: LegacyBridgeAdapter.Request?
        let result: Result<BridgePayload?, Error>
        do {
            let decoded = try LegacyBridgeAdapter.decodeRequest(prompt)
            request = decoded
            guard let api = MinipApi.APIName(rawValue: decoded.api) else {
                throw MinipError(.apiNotFound, "Unknown API: \(decoded.api)")
            }
            guard decoded.supportsPrompt else { throw MinipError(.notSupported, "This API does not support legacy synchronous calls") }
            guard let webView = webView as? MWebView else { throw MinipError(.invalidState, "The calling page is unavailable") }
            let parameter = MinipApi.Parameter(webView: webView, data: decoded.data)
            result = .success(try MinipApi.shared.callSync(apiName: api, param: parameter))
        } catch { result = .failure(error) }
        return LegacyBridgeAdapter.encode(result, for: request)
    }

    // LEGACY_BRIDGE_COMPAT: Old sqliteOpenDB created missing parent directories.
    // Route this through the current filesystem API so its context and path
    // checks also run before any compatibility-related filesystem mutation.
    @MainActor
    private static func prepareLegacyDatabaseDirectory(_ request: LegacyBridgeAdapter.Request, webView: MWebView) throws {
        guard request.api == "sqliteOpenDB", case .string(let path) = request.data["path"] else { return }
        let parent = (path as NSString).deletingLastPathComponent
        guard !parent.isEmpty else { return }
        do {
            _ = try MinipApi.shared.callSync(apiName: .fsMkdir, param: .init(webView: webView, data: ["path": .string(parent), "recursive": .bool(true)]))
        } catch {
            guard MinipError.wrapping(error).code == .alreadyExists else { throw error }
        }
    }
}
