//
//  AppDelegate.swift
//  minip
//
//  Created by LZY on 2023/9/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    // MARK: Scene

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    // MARK: App Delegate

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        _ = MWebViewPool.shared
        NotificationCenter.default.post(name: .mainControllerInitSuccess, object: nil)
        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        guard let serv = MiniAppManager.shared.httpServer else {
            logger.debug("[enter foreground] not create server")
            return
        }
        guard let _ = MiniAppManager.shared.openedApp else {
            logger.debug("[enter foreground] no app opened")
            return
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
