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
        let mainVC = UITabBarController()
        mainVC.viewControllers = [
            {
                let vc = UINavigationController(rootViewController: HomeViewController())
                vc.tabBarItem = UITabBarItem(title: "Projects", image: UIImage(systemName: "shippingbox.fill"), tag: 1)
                return vc
            }(),
            {
                let vc = UIHostingController(rootView: FileBrowserView())
                vc.tabBarItem = UITabBarItem(title: "Files", image: UIImage(systemName: "folder.fill"), tag: 1)
                return vc
            }(),
            {
                let vc = UIHostingController(rootView: SettingsView())
                vc.tabBarItem = UITabBarItem(title: "Settings", image: UIImage(systemName: "gear"), tag: 2)
                return vc
            }(),
        ]
        
        window.rootViewController = mainVC
        window.makeKeyAndVisible()
        _ = MWebViewPool.shared
        _ = MiniV2Egine.shared
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

            MiniAppManager.shared.openMiniAppV2(app: app, rc: window?.rootViewController, animated: false)
        }

        return false
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
        if app.landscape == true {
            if #available(iOS 16.0, *) {
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
            } else {
                UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
            }
        }

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
