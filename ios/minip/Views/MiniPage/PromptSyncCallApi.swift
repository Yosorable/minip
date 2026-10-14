import WebKit

extension MiniPageViewController {
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        // LEGACY_BRIDGE_COMPAT: Remove this early branch when retiring SDK 1.x.
        // MessagePack requests continue through the V2 path below.
        if LegacyBridgeAdapter.recognizesPrompt(prompt) {
            completionHandler(LegacyNativeInteraction.handlePrompt(prompt, webView: webView))
            return
        }
        let result: Result<BridgePayload?, Error>
        do {
            let request = try BridgeCodec.decodeRequest(prompt)
            guard let api = MinipApi.APIName(rawValue: request.api) else {
                throw MinipError(.apiNotFound, "Unknown API: \(request.api)")
            }
            guard let webView = webView as? MWebView else {
                throw MinipError(.invalidState, "The calling page is unavailable")
            }
            let parameter = MinipApi.Parameter(webView: webView, data: request.data ?? [:])
            result = .success(try MinipApi.shared.callSync(apiName: api, param: parameter))
        } catch {
            result = .failure(error)
        }
        completionHandler(try? BridgeCodec.encode(result))
    }
}
