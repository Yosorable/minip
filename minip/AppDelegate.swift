//
//  AppDelegate.swift
//  minip
//
//  Created by LZY on 2023/9/23.
//

import SwiftUI
import UIKit
import Defaults

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        self.window = window
        let mainVC = UITabBarController()
        
        window.overrideUserInterfaceStyle = if Defaults[.colorScheme] == 1 { .light } else if Defaults[.colorScheme] == 2 { .dark } else { .unspecified }

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
                let vc = UIHostingController(rootView: FileBrowserView())
                vc.tabBarItem = UITabBarItem(title: i18n("Files"), image: UIImage(systemName: "folder.fill"), tag: 1)
                return vc
            }(),
            {
                let vc = UIHostingController(rootView: SettingsView())
                vc.tabBarItem = UITabBarItem(title: i18n("Settings"), image: UIImage(systemName: "gear"), tag: 2)
                return vc
            }(),
        ]

        window.rootViewController = mainVC
        window.makeKeyAndVisible()
        _ = MWebViewPool.shared
        NotificationCenter.default.post(name: .mainControllerInitSuccess, object: nil)
        return true
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool
    {
        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return false
        }

        do {
            try URLSchemeHandler.shared.handle(url.absoluteString)
            return true
        } catch {
            logger.debug("[url scheme handler] \(error.localizedDescription)")
            return false
        }
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        guard let serv = MiniAppManager.shared.server else {
            logger.debug("[enter foreground] not create server")
            return
        }
        guard let app = MiniAppManager.shared.openedApp else {
            logger.debug("[enter foreground] no app opened")
            return
        }

        // fix bug: 横屏自动变成竖屏
//        if app.landscape == true {
//            if #available(iOS 16.0, *) {
//                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
//                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
//            } else {
//                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
//            }
//        }

        Task {
            if await serv.isListening {
                print("[enter foreground] server is running")
                return
            }
            print("[enter foreground] server not run, try to run")
            try? await serv.run()
        }
    }
}
