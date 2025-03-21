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

        if let permission = apiName.requestPermissionType() {
            MiniAppManager.shared.getOrRequestPermission(permissionType: permission, onSuccess: { [weak self] in
                self?.callApi(replyHandler: replyHandler, apiName: apiName, jsonObj: jsonObj, param: param)
            }, onFailed: { _ in
                replyHandler(nil, "No permission")
            }, parentVC: (message.webView as? MWebView)?.holderObject as? UIViewController)
        } else {
            self.callApi(replyHandler: replyHandler, apiName: apiName, jsonObj: jsonObj, param: param)
        }
    }

    func callApi(replyHandler: @escaping (Any?, String?) -> Void, apiName: MinipApi.APIName, jsonObj: [String: Any], param: MinipApi.Parameter) {
        let api = MinipApi.shared
        switch apiName {
        case .ping:
            var res = MinipApi.InteropUtils.succeed()
            if let req = jsonObj["data"] as? String {
                res.data = req
            }
            do {
                let encoder = JSONEncoder()
                let resData = try encoder.encode(res)
                replyHandler(String(data: resData), nil)
            } catch {
                replyHandler(nil, error.localizedDescription)
            }
        case .getInstalledAppList:
            api.getInstalledAppList(replyHandler: replyHandler)
        case .navigateTo:
            api.navigateTo(param: param, replyHandler: replyHandler)
        case .navigateBack:
            api.navigateBack(param: param, replyHandler: replyHandler)
        case .redirectTo:
            api.redirectTo(param: param, replyHandler: replyHandler)
        case .openWebsite:
            api.openWebsite(param: param, replyHandler: replyHandler)
        case .openSettings:
            api.openSettings(param: param, replyHandler: replyHandler)
        case .showAppDetail:
            api.showAppDetail(param: param, replyHandler: replyHandler)
        case .closeApp:
            api.closeApp(param: param, replyHandler: replyHandler)
        case .installApp:
            api.installApp(param: param, replyHandler: replyHandler)
        case .setNavigationBarTitle:
            api.setNavigationBarTitle(param: param, replyHandler: replyHandler)
        case .setNavigationBarColor:
            api.setNavigationBarColor(param: param, replyHandler: replyHandler)
        case .enablePullDownRefresh:
            api.enablePullDownRefresh(param: param, replyHandler: replyHandler)
        case .disablePullDownRefresh:
            api.disablePullDownRefresh(param: param, replyHandler: replyHandler)
        case .startPullDownRefresh:
            api.startPullDownRefresh(param: param, replyHandler: replyHandler)
        case .stopPullDownRefresh:
            api.stopPullDownRefresh(param: param, replyHandler: replyHandler)
        case .showHUD:
            api.showHUD(param: param, replyHandler: replyHandler)
        case .hideHUD:
            api.hideHUD(param: param, replyHandler: replyHandler)
        case .showAlert:
            api.showAlert(param: param, replyHandler: replyHandler)
        case .previewImage:
            api.previewImage(param: param, replyHandler: replyHandler)
        case .previewVideo:
            api.previewVideo(param: param, replyHandler: replyHandler)
        case .vibrate:
            api.vibrate(param: param, replyHandler: replyHandler)
        case .getClipboardData:
            api.getClipboardData(param: param, replyHandler: replyHandler)
        case .setClipboardData:
            api.setClipboardData(param: param, replyHandler: replyHandler)
        case .getKVStorage:
            api.getKVStorage(param: param, replyHandler: replyHandler)
        case .setKVStorage:
            api.setKVStorage(param: param, replyHandler: replyHandler)
        case .deleteKVStorage:
            api.deleteKVStorage(param: param, replyHandler: replyHandler)
        case .clearKVStorage:
            api.clearKVStorage(param: param, replyHandler: replyHandler)
        case .showPicker:
            api.showPicker(param: param, replyHandler: replyHandler)
        case .scanQRCode:
            api.scanQRCode(param: param, replyHandler: replyHandler)
        case .getDeviceInfo:
            api.getDeviceInfo(param: param, replyHandler: replyHandler)
        case .sqliteOpenDB:
            api.sqliteOpenDB(param: param, replyHandler: replyHandler)
        case .sqliteCloseDB:
            api.sqliteCloseDB(param: param, replyHandler: replyHandler)
        case .sqlitePrepare:
            api.sqlitePrepare(param: param, replyHandler: replyHandler)
        case .sqliteStatementAll:
            api.sqliteStatementAll(param: param, replyHandler: replyHandler)
        case .sqliteStatementRun:
            api.sqliteStatementRun(param: param, replyHandler: replyHandler)
        case .setMemoryStorage:
            api.setMemoryStorage(param: param, replyHandler: replyHandler)
        case .setMemoryStorageIfNotExist:
            api.setMemoryStorageIfNotExist(param: param, replyHandler: replyHandler)
        case .getMemoryStorage:
            api.getMemoryStorage(param: param, replyHandler: replyHandler)
        case .removeMemoryStorage:
            api.removeMemoryStorage(param: param, replyHandler: replyHandler)
        case .clearMemoryStorage:
            api.clearMemoryCache(param: param, replyHandler: replyHandler)
        default:
            replyHandler(nil, "API \(apiName.rawValue) is not implemented or not allowed")
        }
    }
}
