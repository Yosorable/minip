//
//  Prompt.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

import WebKit

extension MiniPageViewController {
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

        guard let apiName = MinipApi.APIName(rawValue: apiName), let webView = webView as? MWebView else {
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

        let wid = webView.id ?? -1
        logger.debug("[minip-api-sync] call api [\(apiName.rawValue)] from [webview:\(wid == -1 ? "unknown" : "\(wid)")]")

        let api = MinipApi.shared
        let param = MinipApi.Parameter(webView: webView, data: jsonObj["data"])
        let replyHandler: (Any?, String?) -> Void = { res, _ in
            completionHandler(res as? String)
        }

        switch apiName {
        case .getKVStorageSync,
             .setKVStorageSync,
             .deleteKVStorageSync,
             .clearKVStorageSync,
             .getDeviceInfoSync,
             .fsAccessSync,
             .fsMkdirSync,
             .fsReadDirSync,
             .fsRmdirSync,
             .fsReadFileSync,
             .fsWriteFileSync,
             .fsAppendFileSync,
             .fsCopyFileSync,
             .fsUnlinkSync,
             .fsRenameSync,
             .fsStatSync,
             .fsTruncateSync,
             .fsRmSync:
            api.call(apiName: apiName, param: param, replyHandler: replyHandler)
        default:
            completionHandler("API \(apiName.rawValue) is not implemented or not allowed")
        }
    }
}
