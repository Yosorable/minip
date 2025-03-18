//
//  SceneDelegate.swift
//  minip
//
//  Created by LZY on 2025/3/16.
//

import Defaults
import SwiftUI
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        let mainVC = UITabBarController()

        window?.overrideUserInterfaceStyle = if Defaults[.colorScheme] == 1 { .light } else if Defaults[.colorScheme] == 2 { .dark } else { .unspecified }

        // disable ipad top tabbar on ios 18
//        if #available(iOS 18.0, *) {
//            if UIDevice.current.userInterfaceIdiom == .pad {
//                mainVC.traitOverrides.horizontalSizeClass = .compact
//
//            }
//        }
        mainVC.viewControllers = [
            {
                let vc = UINavigationController(rootViewController: HomeViewController())
                vc.navigationBar.prefersLargeTitles = true
                vc.tabBarItem = UITabBarItem(title: i18n("Projects"), image: UIImage(systemName: "shippingbox.fill"), tag: 0)
                return vc
            }(),
            {
                let vc = UINavigationController(rootViewController: FileBrowserViewController(path: "/", folderURL: Global.shared.documentsRootURL))
                vc.navigationBar.prefersLargeTitles = true
                vc.tabBarItem = UITabBarItem(title: i18n("Files"), image: UIImage(systemName: "folder.fill"), tag: 1)
                return vc
            }(),
            {
                let vc = UIHostingController(rootView: SettingsView())
                vc.tabBarItem = UITabBarItem(title: i18n("Settings"), image: UIImage(systemName: "gear"), tag: 2)
                return vc
            }(),
        ]

        window?.rootViewController = mainVC
        window?.makeKeyAndVisible()

        // url scheme on app startup
        if let url = connectionOptions.urlContexts.first?.url {
            handleURL(url: url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        let url = urlContext.url
        handleURL(url: url)
    }
}

extension SceneDelegate {
    func handleURL(url: URL) {
        do {
            try URLSchemeHandler.shared.handle(url.absoluteString)
        } catch {
            logger.debug("[url scheme handler] \(error.localizedDescription)")
        }
    }
}
