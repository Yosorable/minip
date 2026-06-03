//
//  App.swift
//  minip
//
//  Created by LZY on 2025/2/9.
//

extension MinipApi {
    func getInstalledAppList(replyHandler: @escaping (Any?, String?) -> Void) {
        Task {
            let appInfos = MiniAppManager.shared.getAppInfos()
            await MainActor.run {
                replyHandler(InteropUtils.succeedWithData(data: appInfos).toJsonString(), nil)
            }
        }
    }

    func getAppInfo(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        var appInfo = vc.app
        appInfo.files = nil
        replyHandler(InteropUtils.succeedWithData(data: appInfo).toJsonString(), nil)
    }

    func showAppDetail(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        vc.showAppDetail()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func closeApp(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        vc.close()
        replyHandler(InteropUtils.succeed().toJsonString(), nil)
    }

    func installApp(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let _ = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let url = (param.data as? [String: String])?["url"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        DownloadMiniAppPackageToTmpFolder(url, onError: { err in
            replyHandler(InteropUtils.fail(msg: err.localizedDescription).toJsonString(), nil)
        }, onSuccess: { pkgURL in
            InstallMiniApp(pkgFile: pkgURL, onSuccess: {
                replyHandler(InteropUtils.succeed().toJsonString(), nil)
            }, onFailed: { errMsg in
                replyHandler(InteropUtils.fail(msg: errMsg).toJsonString(), nil)
            })
        })
    }

    func updateCurrentApp(param: Parameter, replyHandler: @escaping (Any?, String?) -> Void) {
        guard let vc = param.webView?.holderObject as? MiniPageViewController else {
            return
        }
        guard let url = (param.data as? [String: String])?["url"] else {
            replyHandler(InteropUtils.fail(msg: "Error parameter").toJsonString(), nil)
            return
        }
        let appID = vc.app.appId
        DownloadMiniAppPackageToTmpFolder(url, onError: { err in
            replyHandler(InteropUtils.fail(msg: err.localizedDescription).toJsonString(), nil)
        }, onSuccess: { pkgURL in
            InstallMiniApp(pkgFile: pkgURL, onSuccess: {
                replyHandler(InteropUtils.succeed().toJsonString(), nil)
            }, onFailed: { errMsg in
                replyHandler(InteropUtils.fail(msg: errMsg).toJsonString(), nil)
            }, validateAppInfoFunc: { appInfo in
                return appInfo.appId == appID
            })
        })
    }
}
