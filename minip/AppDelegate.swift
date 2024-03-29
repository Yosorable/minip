//
//  AppDelegate.swift
//  minip
//
//  Created by LZY on 2023/9/23.
//

import UIKit
import SwiftUI
import PKHUD

@main
class AppDelegate: UIResponder, UIApplicationDelegate  {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow()
        self.window = window
        window.rootViewController = UIHostingController(rootView: TabView {
            HomeView()
                .tabItem {
                    Label("Projects", systemImage: "shippingbox")
                }
            FileBrowserView()
                .tabItem {
                    Label("Files", systemImage: "folder")
                }
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        })
        window.makeKeyAndVisible()
        _ = MWebViewPool.shared
        NotificationCenter.default.post(name: NSNotification.Name("kMainControllerInitSuccessNotiKey"), object: nil)

        return true
    }

    func application(_ application: UIApplication,
                     open url: URL,
                     options: [UIApplication.OpenURLOptionsKey : Any] = [:] ) -> Bool {

        guard let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true),
              let host = components.host else {
            return false
        }

        // minip://open/{appId | appName}
        if host == "open" {
            guard let appIdOrName = components.path?.deletingPrefixSuffix("/") else {
                return false
            }
            if MiniAppManager.shared.openedApp?.appId == appIdOrName || MiniAppManager.shared.openedApp?.name == appIdOrName {
                return true
            }
            if MiniAppManager.shared.openedApp != nil {
                window?.rootViewController?.children.first?.dismiss(animated: false)
                MiniAppManager.shared.clearOpenedApp()
            }

            var foundApp: AppInfo?

            for ele in MiniAppManager.shared.getAppInfos() {
                if ele.appId == appIdOrName || ele.name == appIdOrName {
                    foundApp = ele
                    break
                }
            }
            
            guard let app = foundApp else {
                return false
            }

            MiniAppManager.shared.openMiniApp(app: app, rc: window?.rootViewController, animated: false)
        }

        return false
    }
}
