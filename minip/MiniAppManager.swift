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

class MiniAppManager {
    static let shared = MiniAppManager()

    var appTmpStore: [String:String] = [String:String]()
    var openedApp: AppInfo? = nil
    var observedData = [String: Set<Int>]() // data key: webview id
    
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
        self.appTmpStore.removeAll()
        self.observedData.removeAll()
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
}

extension MiniAppManager {
    @MainActor
    private func createMiniAppRootViewController(appInfo: AppInfo) -> UIViewController {
        var vc: UIViewController
        if let tabs = appInfo.tabs, tabs.count > 0 {
            let tabc = PannableTabBarController()
            
            var pages = [UINavigationController]()
            for (idx, ele) in tabs.enumerated() {
                let page = UINavigationController(rootViewController: MiniPageViewController(app: appInfo, page: ele.path, title: ele.title, isRoot: true))
                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                pages.append(page)
//                setupMiniAppCapsuleButton(navigationController: page)
            }
            tabc.viewControllers = pages
            
            if let tc = appInfo.tintColor {
                let tint = UIColor(hex: tc)
                pages.forEach {ele in
                    ele.navigationBar.tintColor = tint
                }
                tabc.tabBar.tintColor = tint
            }
            
            vc = tabc
        } else {
            let nvc = PannableNavigationViewController(rootViewController: MiniPageViewController(app: appInfo, isRoot: true))
            if let tc = appInfo.tintColor {
                nvc.navigationBar.tintColor = UIColor(hex: tc)
            }
            vc = nvc
//            setupMiniAppCapsuleButton(navigationController: nvc)
        }
        
        if appInfo.colorScheme == "dark" {
            vc.overrideUserInterfaceStyle = .dark
        } else if appInfo.colorScheme == "light" {
            vc.overrideUserInterfaceStyle = .light
        }
        
        return vc
    }
    
    func openMiniApp(parent: UIViewController, appInfo: AppInfo, animated: Bool = true, completion: (()->Void)? = nil) {
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
            
            await parent.present(vc, animated: animated, completion: {
                completion?()
            })
        }
    }
    
    private func setupMiniAppCapsuleButton(navigationController: UINavigationController) {
        let moreButton = UIButton(type: .system)
        moreButton.setImage(UIImage(named: "capsule-more-icon"), for: .normal)
        moreButton.addTarget(self, action: #selector(globalButtonTapped), for: .touchUpInside)
        
        
        let closeButton = UIButton(type: .system)
        closeButton.setImage(UIImage(named: "capsule-close-icon"), for: .normal)
        closeButton.addTarget(self, action: #selector(globalButtonTapped), for: .touchUpInside)
        
        // 将按钮添加到 navigationBar
        let stackView = UIStackView(arrangedSubviews: [moreButton, closeButton])
        stackView.axis = .horizontal
        stackView.spacing = 0
        stackView.distribution = .equalSpacing
        
        
        navigationController.navigationBar.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.trailingAnchor.constraint(equalTo: navigationController.navigationBar.trailingAnchor, constant: -15),
            stackView.centerYAnchor.constraint(equalTo: navigationController.navigationBar.centerYAnchor),
            moreButton.widthAnchor.constraint(equalToConstant: 132 / 3),
            moreButton.heightAnchor.constraint(equalToConstant: 96 / 3),
            closeButton.widthAnchor.constraint(equalToConstant: 132 / 3),
            closeButton.heightAnchor.constraint(equalToConstant: 96 / 3)
        ])
    }
    
    @objc private func globalButtonTapped() {
        print("全局按钮被点击")
    }
}
