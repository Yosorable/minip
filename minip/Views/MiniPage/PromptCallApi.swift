//
//  Prompt.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import WebKit

extension MiniPageViewController: WKUIDelegate {
    func webView(
        _ webView: WKWebView,
        runJavaScriptTextInputPanelWithPrompt prompt: String,
        defaultText: String?,
        initiatedByFrame frame: WKFrameInfo,
        completionHandler: @escaping (String?) -> Void
    ) {
        guard let bodyData = prompt.data(using: .utf8),
              let jsonObj = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
              let apiName = jsonObj["api"] as? String
        else {
            completionHandler(MinipApi.InteropUtils.fail(msg: "Error request").toJsonString())
            return
        }

        guard let apiName = MinipApi.APIName(rawValue: apiName) else {
            do {
                let encoder = JSONEncoder()
                let resData = try encoder.encode(MinipApi.InteropUtils.fail(msg: "API not found"))
                logger.debug("[minip-api] sync call error, req: \(defaultText ?? "")")
                completionHandler(String(data: resData))
            } catch {
                completionHandler(MinipApi.InteropUtils.fail(msg: error.localizedDescription).toJsonString())
            }
            return
        }

        let wid = (webView as? MWebView)?.id ?? -1
        logger.debug("[minip-api] call api [\(apiName.rawValue)] from [webview:\(wid == -1 ? "unknown" : "\(wid)")]")

        let api = MinipApi.shared
        let param = MinipApi.Parameter(webView: webView as? MWebView, data: jsonObj["data"])
        switch apiName {
        case .getKVStorageSync:
            completionHandler(api.getKVStorageSync(param: param))
        case .setKVStorageSync:
            completionHandler(api.setKVStorageSync(param: param))
        case .deleteKVStorageSync:
            completionHandler(api.deleteKVStorageSync(param: param))
        case .clearKVStorageSync:
            completionHandler(api.clearKVStorageSync(param: param))
        case .getDeviceInfoSync:
            completionHandler(MinipApi.InteropUtils.succeedWithData(data: api.getDeviceInfoSync(param: param)).toJsonString())
        default:
            completionHandler("API \(apiName.rawValue) is not implemented or not allowed")
        }
    }
}
