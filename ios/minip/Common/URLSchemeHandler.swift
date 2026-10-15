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
        case dev // minip://dev/{encoded development server URL}
    }

    static let shared = URLSchemeHandler()
    private var developmentTask: Task<Void, Never>?

    public func handle(_ urlStr: String) throws {
        guard let url = NSURLComponents(string: urlStr), url.scheme?.lowercased() == "minip", let method = Methods(rawValue: url.host ?? "") else {
            throw ErrorMsg(errorDescription: "unsupported url scheme")
        }

        if developmentTask != nil {
            developmentTask?.cancel()
            developmentTask = nil
            ProgressHUD.dismiss()
        }

        switch method {
        case .open:
            try open(url.path?.deletingPrefixSuffix("/") ?? "")

        case .install:
            ProgressHUD.animate(interaction: false)
            try install(url.path?.deletingPrefixSuffix("/") ?? "")

        case .dev:
            let serverURL = try DevelopmentProject.serverURL(from: url.path?.deletingPrefixSuffix("/") ?? "")
            connectToDevelopmentServer(serverURL)
        }
    }
}

extension URLSchemeHandler {
    private func connectToDevelopmentServer(_ serverURL: URL) {
        developmentTask?.cancel()
        developmentTask = Task { @MainActor [self] in
            ProgressHUD.animate(interaction: false)
            defer {
                if !Task.isCancelled {
                    ProgressHUD.dismiss()
                    self.developmentTask = nil
                }
            }
            do {
                let project = try await DevelopmentProject.load(from: serverURL)
                guard !Task.isCancelled else {
                    try? FileManager.default.removeItem(at: project.rootURL)
                    return
                }
                guard let scene = self.closeOpenedAppAndGetSceneDelegate(), let parent = scene.window?.rootViewController else {
                    try? FileManager.default.removeItem(at: project.rootURL)
                    throw ErrorMsg(errorDescription: i18n("dev.connection_failed"))
                }
                MiniAppManager.shared.openMiniApp(parent: parent, project: project, animated: false)
            } catch {
                guard !Task.isCancelled else { return }
                logger.error("[Development] Connection failed: \(error.localizedDescription)")
                let alert = UIAlertController(
                    title: i18n("dev.connection_failed"),
                    message: i18n("dev.connection_help") + "\n\n" + error.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: i18n("dev.retry"), style: .default) { [weak self] _ in
                    self?.connectToDevelopmentServer(serverURL)
                })
                alert.addAction(UIAlertAction(title: i18n("Cancel"), style: .cancel))
                if let parent = getTopViewController() {
                    parent.present(alert, animated: true)
                } else {
                    logger.error("[Development] No view controller is available for the connection error")
                }
            }
        }
    }

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
        if MiniAppManager.shared.openedProject?.developmentServerURL == nil,
           MiniAppManager.shared.openedProject?.appId == appIdOrName || MiniAppManager.shared.openedProject?.appInfo.name == appIdOrName {
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
