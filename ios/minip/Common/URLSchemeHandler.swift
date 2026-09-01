//
//  URLSchemeHandler.swift
//  minip
//
//  Created by LZY on 2025/2/14.
//

import Foundation
import ProgressHUD
import UIKit

class URLSchemeHandler {
    public enum Methods: String {
        case open // minip://open/{appname or appid}
        case install // minip://install/{url}
    }

    static let shared = URLSchemeHandler()

    public func handle(_ urlStr: String) throws {
        guard let url = NSURLComponents(string: urlStr), url.scheme?.lowercased() == "minip", let method = Methods(rawValue: url.host ?? "") else {
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
    private func closeOpenedAppAndGetSceneDelegate() -> SceneDelegate? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let sceneDelegate = scene.delegate as? SceneDelegate else {
            return nil
        }
        if MiniAppManager.shared.openedApp != nil {
            sceneDelegate.window?.rootViewController?.children.first?.dismiss(animated: false)
            MiniAppManager.shared.clearOpenedApp()
        }
        return sceneDelegate
    }

    private func open(_ appIdOrName: String) throws {
        if MiniAppManager.shared.openedProject?.appId == appIdOrName || MiniAppManager.shared.openedProject?.appInfo.name == appIdOrName {
            return
        }

        guard let sceneDelegate = closeOpenedAppAndGetSceneDelegate() else {
            throw ErrorMsg(errorDescription: "unknown error")
        }

        var foundProject: InstalledProject?

        for project in MiniAppManager.shared.getInstalledProjects() {
            if project.appId == appIdOrName || project.appInfo.name == appIdOrName {
                foundProject = project
                break
            }
        }

        guard let project = foundProject else {
            throw ErrorMsg(errorDescription: "app doesn't exist")
        }

        guard let vc = sceneDelegate.window?.rootViewController else {
            throw ErrorMsg(errorDescription: "unknown error")
        }

        MiniAppManager.shared.openMiniApp(parent: vc, project: project, animated: false)
    }

    private func install(_ urlStr: String) throws {
        guard let _ = closeOpenedAppAndGetSceneDelegate(), urlStr != "" else {
            throw ErrorMsg(errorDescription: "unknown error")
        }

        DownloadMiniAppPackageToTmpFolder(urlStr, onError: { err in
            showSimpleError(err: err)
        }, onSuccess: { pkgURL in
            Task {
                await InstallMiniApp(pkgFile: pkgURL, onSuccess: {
                    showSimpleSuccess()
                }, onFailed: { errMsg in
                    showSimpleError(err: ErrorMsg(errorDescription: errMsg))
                })
            }
        })
    }
}
