//
//  MiniAppManager.swift
//  minip
//
//  Created by LZY on 2023/9/26.
//

import Foundation
import Defaults
import UIKit

struct RouteParameter: Hashable {
    var path: String
    var title: String?
}

class MiniAppManager {
    static let shared = MiniAppManager()

    var path: [RouteParameter] = []
    var appTmpStore: [String:String] = [String:String]()
    var openedApp: AppInfo? = nil

    func getAppInfos() -> [AppInfo] {
        var tmpApps: [AppInfo] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            fileURLs.forEach { ele in
                let infoURL = ele.appendingPathComponent("info", conformingTo: .json)
                if ele.lastPathComponent != ".Trash" && fileManager.fileExists(atPath: infoURL.path) {
                    do {
                        let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
                        let appDetail = try? decoder.decode(AppInfo.self, from: data)
                        if let ad = appDetail {
                            tmpApps.append(ad)
                        }
                    } catch let error {
                        print("\(error.localizedDescription)")
                    }
                }
            }
        } catch let error {
            print("\(error.localizedDescription)")
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
        
        return tmpApps
    }
    
    func clearOpenedApp() {
        let appId = self.openedApp?.appId
        self.openedApp = nil
        self.path = []
        self.appTmpStore.removeAll()
        if let appId = appId {
            KVStoreManager.shared.removeDB(dbName: appId)
        }
    }
    
    func openMiniApp(app: AppInfo, rc: UIViewController? = nil) {
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
            rc.present(vc, animated: true)
        } else {
            GetTopViewController()?.present(vc, animated: true)
        }
    }
}
