import Foundation
import WebKit

final class MinipNativeInteraction: NSObject, WKScriptMessageHandlerWithReply {
    static let name = BridgeCodec.handlerName

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        Task { @MainActor in
            let result: Result<BridgePayload?, Error>
            do {
                guard let body = message.body as? String, let webView = message.webView as? MWebView else {
                    throw MinipError(.invalidArgument, "Expected a bridge request string")
                }
                let request = try BridgeCodec.decodeRequest(body)
                guard let api = MinipApi.APIName(rawValue: request.api) else {
                    throw MinipError(.apiNotFound, "Unknown API: \(request.api)")
                }
                let parameter = MinipApi.Parameter(webView: webView, data: request.data ?? [:])
                result = .success(try await MinipApi.shared.call(apiName: api, param: parameter))
            } catch {
                result = .failure(error)
            }
            do { replyHandler(try BridgeCodec.encode(result), nil) }
            catch { replyHandler(nil, "Could not encode the bridge response") }
        }
    }
}
