//
//  MiniAppManager.swift
//  minip
//
//  Created by LZY on 2023/9/26.
//

import Foundation
import Defaults
import UIKit
import FlyingFox

struct RouteParameter: Hashable, Codable {
    var path: String
    var title: String?
}

class MiniAppManager {
    static let shared = MiniAppManager()

    var path: [RouteParameter] = []
    var appTmpStore: [String:String] = [String:String]()
    var openedApp: AppInfo? = nil
    var obseredData = [String: Set<Int>]() // data key: webview id
    
    var server: HTTPServer? = nil
    var serverAddress: String? = nil

    func getAppInfos() -> [AppInfo] {
        var tmpApps: [AppInfo] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            fileURLs.forEach { ele in
                let infoURL = ele.appendingPathComponent("app", conformingTo: .json)
                if ele.lastPathComponent != ".Trash" && fileManager.fileExists(atPath: infoURL.path) {
                    do {
                        let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
                        let appDetail = try? decoder.decode(AppInfo.self, from: data)
                        if let ad = appDetail {
                            tmpApps.append(ad)
                        }
                    } catch let error {
                        logger.error("[getAppInfos] \(error.localizedDescription)")
                    }
                }
            }
        } catch let error {
            logger.error("[getAppInfos] \(error.localizedDescription)")
        }
        
        var appIdSortListIndexMap = [String:Int]()
        let appIdSortList = Defaults[.appSortList]
        
        for i in 0..<appIdSortList.count {
            appIdSortListIndexMap[appIdSortList[i]] = i
        }
        
        tmpApps.sort(by: { l, r in
            let idx1 = appIdSortListIndexMap[l.appId]
            let idx2 = appIdSortListIndexMap[r.appId]
            if let i1 = idx1, let i2 = idx2 {
                return i1 < i2
            } else if idx1 != nil {
                return false
            } else if idx2 != nil {
                return true
            }
            return true
        })
        
        var newSortList = [String]()
        tmpApps.forEach { ele in
            newSortList.append(ele.appId)
        }
        if newSortList != appIdSortList {
            Defaults[.appSortList] = newSortList
        }
        
        if tmpApps != Defaults[.appInfoList] {
            Defaults[.appInfoList] = tmpApps
            logger.debug("[getAppInfos] not equal")
        }
        return tmpApps
    }
    
    func getAppInfosFromCache() -> [AppInfo] {
        return Defaults[.appInfoList]
    }

    func clearOpenedApp() {
        let appId = self.openedApp?.appId
        self.openedApp = nil
        self.path = []
        self.appTmpStore.removeAll()
        self.obseredData.removeAll()
        if let appId = appId {
            KVStoreManager.shared.removeDB(dbName: appId)
        }
    }
    
    func openMiniApp(app: AppInfo, rc: UIViewController? = nil, animated: Bool = true) {
        var vc: UINavigationController


        if let tabs = app.tabs, tabs.count > 0 {
            let tabc = UITabBarController()

            var pages = [UIViewController]()
            for (idx, ele) in tabs.enumerated() {
                let page = MiniPageViewController(app: app, page: ele.path, title: ele.title)
                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                pages.append(page)
            }
            tabc.viewControllers = pages

            vc = UINavigationController(rootViewController: tabc)

            if let tc = app.tintColor {
                vc.navigationBar.tintColor = UIColor(hex: tc)
                tabc.tabBar.tintColor = UIColor(hex: tc)
            }
        } else {
            vc = UINavigationController(rootViewController: MiniPageViewController(app: app))
        }

        if app.colorScheme == "dark" {
            vc.overrideUserInterfaceStyle = .dark
        } else if app.colorScheme == "light" {
            vc.overrideUserInterfaceStyle = .light
        }
        vc.modalPresentationStyle = .fullScreen
        MiniAppManager.shared.openedApp = app
        if let rc = rc {
            rc.present(vc, animated: animated)
        } else {
            GetTopViewController()?.present(vc, animated: animated)
        }
    }
    
    func createMiniAppRootVCForPresent(app: AppInfo) -> UIViewController {
        var vc: UINavigationController

        if let tabs = app.tabs, tabs.count > 0 {
            let tabc = UITabBarController()

            var pages = [UIViewController]()
            for (idx, ele) in tabs.enumerated() {
                let page = MiniPageViewController(app: app, page: ele.path, title: ele.title)
                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                pages.append(page)
            }
            tabc.viewControllers = pages

            vc = UINavigationController(rootViewController: tabc)

            if let tc = app.tintColor {
                vc.navigationBar.tintColor = UIColor(hex: tc)
                tabc.tabBar.tintColor = UIColor(hex: tc)
            }
        } else {
            vc = UINavigationController(rootViewController: MiniPageViewController(app: app))
        }

        if app.colorScheme == "dark" {
            vc.overrideUserInterfaceStyle = .dark
        } else if app.colorScheme == "light" {
            vc.overrideUserInterfaceStyle = .light
        }
        vc.modalPresentationStyle = .fullScreen
        MiniAppManager.shared.openedApp = app
        return vc
    }
}
