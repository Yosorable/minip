//
//  MinipNativeInteraction.swift
//  minip
//
//  Created by LZY on 2024/12/14.
//

import Foundation
import WebKit

class MinipNativeInteraction: NSObject, WKScriptMessageHandlerWithReply {
    static let name = "MinipNativeInteraction"
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let body = message.body as? String,
              let bodyData = body.data(using: .utf8),
              let jsonObj = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let apiName = jsonObj["api"] as? String
        else {
            replyHandler(nil, "Error request")
            return
        }

        guard let apiName = MinipApi.APIName(rawValue: apiName) else {
            do {
                let encoder = JSONEncoder()
                let resData = try encoder.encode(MinipApi.InteropUtils.fail(msg: "API not found"))
                logger.debug("[minip-api-v3] call error, req: \(body)")
                replyHandler(String(data: resData), nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }
            return
        }

        let wid = (message.webView as? MWebView)?.id ?? -1
        logger.debug("[minip-api-v3] call api [\(apiName.rawValue)] from [webview:\(wid == -1 ? "unknown" : "\(wid)")] with [\(body.count < 1000 ? body : "data length: \(body.count)")]")

        let param = MinipApi.Parameter(webView: message.webView as? MWebView, data: jsonObj["data"])

        MinipApi.shared.call(apiName: apiName, param: param, replyHandler: replyHandler)
    }
}
