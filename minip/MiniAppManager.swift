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
    
    var openedDatabase: [String:SQLiteDatabase] = [String:SQLiteDatabase]()

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
        if !self.openedDatabase.isEmpty {
            self.openedDatabase.forEach { k, v in
                v.close()
            }
            self.openedDatabase.removeAll()
        }
    }
    
    func initWebServer() async {
        var _server: HTTPServer!
        if self.server == nil {
            serverAddress = "http://127.0.0.1:60008"
            _server = HTTPServer(address: try! .inet(ip4: "127.0.0.1", port: 60008))
            MiniAppManager.shared.server = _server
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

            let dirHandler = DirectoryHTTPHandler(root: documentsURL)
            await _server.appendRoute("GET /*") { req in
                var _req: HTTPRequest = req
                guard let appName = MiniAppManager.shared.openedApp?.name else {
                    return HTTPResponse(statusCode: .notFound)
                }
                _req.path = "/\(appName)" + req.path
                print(_req.path)
                do {
                    return try await dirHandler.handleRequest(_req)
                } catch {
                    return HTTPResponse(statusCode: .notFound)
                }
            }
            
            await _server.appendRoute("POST /closeApp") { _ in
                DispatchQueue.main.async {
                    if let mvc = GetTopViewController() as? MiniPageViewController {
                        mvc.close()
                    }
                }
                return HTTPResponse(statusCode: .ok)
            }
            
            await _server.appendRoute("POST /ping") { req in
                var res = "pong".data(using: .utf8)!
                do {
                    let data = try await req.bodyData
                    res.append(" ".data(using: .utf8)!)
                    res.append(data)
                } catch {
                    
                }
                return HTTPResponse(statusCode: .ok, body: res)
            }
        } else {
            server = MiniAppManager.shared.server!
        }
        do {
            logger.debug("[init-server] try to run server")
            try await _server.run()
            logger.debug("[init-server] run server success")
        } catch {
            logger.error("[init-server] error occurs \(error.localizedDescription)")
        }
    }

    func openMiniAppV2(app: AppInfo, rc: UIViewController? = nil, animated: Bool = true) {
        guard openedApp == nil else {
            return
        }
        
        Task {
            if app.webServerEnabled == true {
                let needToStartServer = self.server == nil ? true : (await self.server!.isListening == false)
                if needToStartServer {
                    logger.debug("[open-app] try to start server")
                    await self.initWebServer()
                }
                // todo: webserver has bug
//                var addr = ""
//
//                guard let _server = self.server else {
//                    return
//                }
//                
//                try? await _server.waitUntilListening()
//                
//                if let ipPort = await _server.listeningAddress {
//                    switch ipPort {
//                    case .ip4(_, port: let port): addr = "http://127.0.0.1:\(port)"
//                    case .ip6(_, port: let port): addr = "http://[::1]:\(port)"
//                    case .unix(let unixAddr):
//                        addr = "http://" + unixAddr
//                    }
//                    logger.debug("[getAddress] \(addr)")
//                    MiniAppManager.shared.serverAddress = addr
//                }
            }
        }
        
        Task {
            let viewController = await MainActor.run {
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
                self.openedApp = app
                
                if app.landscape == true {
                    if #available(iOS 16.0, *) {
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                    } else {
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                    }
                }
                return vc
            }
            
            if app.landscape == true {
                try await Task.sleep(nanoseconds: 220_000_000)
            }
            
            await MainActor.run {
                logger.debug("[open-app] opening \(app.name) \(app.appId)")
                (rc ?? GetTopViewController())?.present(viewController, animated: animated)
            }
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

extension MiniAppManager {
    @MainActor
    private func createMiniAppRootViewController(appInfo: AppInfo) -> UIViewController {
        var vc: UINavigationController
        if let tabs = appInfo.tabs, tabs.count > 0 {
            let tabc = UITabBarController()
            
            var pages = [UIViewController]()
            for (idx, ele) in tabs.enumerated() {
                let page = MiniPageViewController(app: appInfo, page: ele.path, title: ele.title, isRoot: true)
                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                pages.append(page)
            }
            tabc.viewControllers = pages
            
            vc = PannableNavigationViewController(rootViewController: tabc)
            
            if let tc = appInfo.tintColor {
                vc.navigationBar.tintColor = UIColor(hex: tc)
                tabc.tabBar.tintColor = UIColor(hex: tc)
            }
        } else {
            vc = PannableNavigationViewController(rootViewController: MiniPageViewController(app: appInfo, isRoot: true))
        }
        
        if appInfo.colorScheme == "dark" {
            vc.overrideUserInterfaceStyle = .dark
        } else if appInfo.colorScheme == "light" {
            vc.overrideUserInterfaceStyle = .light
        }
        
        return vc
    }

    func openMiniApp(parent: UIViewController, appInfo: AppInfo, completion: (()->Void)?) {
        let app = appInfo
        
        Task {
            var addr = ""
            if app.webServerEnabled == true {
                var server: HTTPServer
                if MiniAppManager.shared.server == nil {
                    server = HTTPServer(address: try! .inet(ip4: "127.0.0.1", port: 60008))
                    MiniAppManager.shared.server = server
                    let fileManager = FileManager.default
                    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    
                    let dirHandler = DirectoryHTTPHandler(root: documentsURL)
                    await server.appendRoute("GET /*") { req in
                        var _req: HTTPRequest = req
                        guard let appName = MiniAppManager.shared.openedApp?.name else {
                            return HTTPResponse(statusCode: .notFound)
                        }
                        _req.path = "/\(appName)" + req.path
                        print(_req.path)
                        do {
                            return try await dirHandler.handleRequest(_req)
                        } catch {
                            return HTTPResponse(statusCode: .notFound)
                        }
                    }
                    
                    await server.appendRoute("POST /closeApp") { _ in
                        DispatchQueue.main.async {
                            if let mvc = GetTopViewController() as? MiniPageViewController {
                                mvc.close()
                            }
                        }
                        return HTTPResponse(statusCode: .ok)
                    }
                    
                    await server.appendRoute("POST /ping") { req in
                        var res = "pong".data(using: .utf8)!
                        do {
                            let data = try await req.bodyData
                            res.append(" ".data(using: .utf8)!)
                            res.append(data)
                        } catch {
                            
                        }
                        return HTTPResponse(statusCode: .ok, body: res)
                    }
                } else {
                    server = MiniAppManager.shared.server!
                }
                
                Task {
                    try? await server.run()
                }
                try? await server.waitUntilListening()
                if let ipPort = await server.listeningAddress {
                    switch ipPort {
                    case .ip4(_, port: let port): addr = "http://127.0.0.1:\(port)"
                    case .ip6(_, port: let port): addr = "http://[::1]:\(port)"
                    case .unix(let unixAddr):
                        addr = "http://" + unixAddr
                    }
                    logger.info("[getAddress] \(addr)")
                    MiniAppManager.shared.serverAddress = addr
                }
            }
            
            let vc = await self.createMiniAppRootViewController(appInfo: appInfo)
            
            await MainActor.run {
                vc.modalPresentationStyle = .overFullScreen
                MiniAppManager.shared.openedApp = appInfo
            }
            
            if appInfo.landscape == true {
                await MainActor.run {
                    if #available(iOS 16.0, *) {
                        let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                        windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                    } else {
                        UIDevice.current.setValue(UIInterfaceOrientation.landscapeLeft.rawValue, forKey: "orientation")
                    }
                }
                try? await Task.sleep(nanoseconds: 220_000_000)
            }
            
            await parent.present(vc, animated: true, completion: {
                completion?()
            })
        }
    }
}
