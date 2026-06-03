//
//  URLSchemeHandler.swift
//  minip
//
//  Created by LZY on 2025/2/14.
//

import Foundation
import ProgressHUD
import UIKit

public class URLSchemeHandler {
    public enum Methods: String {
        case open // <scheme>://open/{appname or appid}
        case install // <scheme>://install/{url}
    }

    public static let shared = URLSchemeHandler()

    public func handle(_ urlStr: String) throws {
        guard let scheme = MiniAppManager.shared.urlScheme, !scheme.isEmpty else {
            throw ErrorMsg(errorDescription: "url scheme not configured")
        }
        guard let url = NSURLComponents(string: urlStr), url.scheme?.lowercased() == scheme.lowercased(), let method = Methods(rawValue: url.host ?? "") else {
            throw ErrorMsg(errorDescription: "unsupported url scheme")
        }

        switch method {
        case .open:
            try open(url.path?.deletingPrefixSuffix("/") ?? "")

        case .install:
            ProgressHUD.animate(interaction: false)
            try install(url.path?.deletingPrefixSuffix("/") ?? "")
        }
    }
}

extension URLSchemeHandler {
    private func closeOpenedAppAndGetRootVC() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first else {
            return nil
        }
        if MiniAppManager.shared.openedApp != nil {
            window.rootViewController?.children.first?.dismiss(animated: false)
            MiniAppManager.shared.clearOpenedApp()
        }
        return window.rootViewController
    }

    private func open(_ appIdOrName: String) throws {
        if MiniAppManager.shared.openedApp?.appId == appIdOrName || MiniAppManager.shared.openedApp?.name == appIdOrName {
            return
        }

        guard let vc = closeOpenedAppAndGetRootVC() else {
            throw ErrorMsg(errorDescription: "unknown error")
        }

        var foundApp: AppInfo?

        for ele in MiniAppManager.shared.getAppInfos() {
            if ele.appId == appIdOrName || ele.name == appIdOrName {
                foundApp = ele
                break
            }
        }

        guard let app = foundApp else {
            throw ErrorMsg(errorDescription: "app doesn't exist")
        }

        MiniAppManager.shared.openMiniApp(parent: vc, appInfo: app, animated: false)
    }

    private func install(_ urlStr: String) throws {
        guard let _ = closeOpenedAppAndGetRootVC(), urlStr != "" else {
            throw ErrorMsg(errorDescription: "unknown error")
        }

        DownloadMiniAppPackageToTmpFolder(urlStr, onError: { err in
            showSimpleError(err: err)
        }, onSuccess: { pkgURL in
            InstallMiniApp(pkgFile: pkgURL, onSuccess: {
                showSimpleSuccess()
            }, onFailed: { errMsg in
                showSimpleError(err: ErrorMsg(errorDescription: errMsg))
            })
        })
    }
}
