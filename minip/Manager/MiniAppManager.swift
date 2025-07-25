//
//  MiniAppManager.swift
//  minip
//
//  Created by LZY on 2023/9/26.
//

import Defaults
import FlyingFox
import Foundation
import Kingfisher
import SwiftLMDB
import UIKit

class MiniAppManager {
    static let shared = MiniAppManager()
    let EmojiAppNames = ["🍇", "🍈", "🍉", "🍊", "🍋", "🍌", "🍍", "🥭", "🍎", "🍏", "🍐", "🍑", "🍒", "🍓", "🥝", "🍅", "🥥", "🥑", "🍆", "🥔", "🥕", "🌽", "🌶", "🥒", "🥬", "🥦", "🍄", "🥜", "🌰"]
    var openedApp: AppInfo?
    var webViewLogs = [String]()

    var httpServer: HTTPServer?
    var serverAddress: String?
    var appMemoryStorage = [String: String]()

    private let fsLock = NSLock()
    private var fileSystemManager: FileSystemManager?

    func appendWebViewLog(_ msg: String) {
        while self.webViewLogs.count >= 500 {
            self.webViewLogs.remove(at: 0)
        }
        self.webViewLogs.append(msg)
    }

    func getAppInfos() -> [AppInfo] {
        var tmpApps: [AppInfo] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            for ele in fileURLs {
                let infoURL = ele.appendingPathComponent("app", conformingTo: .json)
                if ele.lastPathComponent != ".Trash", fileManager.fileExists(atPath: infoURL.path) {
                    do {
                        let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
                        let appDetail = try? decoder.decode(AppInfo.self, from: data)
                        if let ad = appDetail {
                            tmpApps.append(ad)
                        }
                    } catch {
                        logger.error("[getAppInfos] \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            logger.error("[getAppInfos] \(error.localizedDescription)")
        }

        var appIdSortListIndexMap = [String: Int]()
        let appIdSortList = Defaults[.appSortList]

        for i in 0 ..< appIdSortList.count {
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
        for ele in tmpApps {
            newSortList.append(ele.appId)
        }
        if newSortList != appIdSortList {
            Defaults[.appSortList] = newSortList
        }

        // ignore files property
        let withoutFiles = tmpApps.map {
            var t = $0
            t.files = nil
            return t
        }
        if withoutFiles != Defaults[.appInfoList] {
            Defaults[.appInfoList] = withoutFiles
            logger.debug("[getAppInfos] not equal")
        }

        return tmpApps
    }

    func getAppInfosFromCache() -> [AppInfo] {
        return Defaults[.appInfoList]
    }

    func getFSManager() -> FileSystemManager? {
        if self.fileSystemManager != nil {
            return self.fileSystemManager
        }

        self.fsLock.lock()
        defer { self.fsLock.unlock() }

        if self.fileSystemManager == nil, let appInfo = openedApp {
            self.fileSystemManager = FileSystemManager(appInfo: appInfo)
        }

        return self.fileSystemManager
    }

    func clearOpenedApp() {
        let appId = self.openedApp?.appId
        self.openedApp = nil
        self.webViewLogs.removeAll()
        if let appId = appId {
            KVStorageManager.shared.removeDB(dbName: appId)
        }
        SQLiteDBManager.shared.clear()
        self.appMemoryStorage.removeAll()

        logger.debug("[Kingfisher] closed app, cleaning memory image cache")
        KingfisherManager.shared.cache.clearMemoryCache()

        self.fileSystemManager = nil
    }
}

extension MiniAppManager {
    @MainActor
    private func createMiniAppRootViewController(appInfo: AppInfo) -> UIViewController {
        var vc: UIViewController
        var orientations: UIInterfaceOrientationMask?
        if let ori = appInfo.orientation {
            if ori == "landscape" {
                orientations = .landscape
            } else if ori == "portrait" {
                orientations = .portrait
            }
        }

        if let tabs = appInfo.tabs, tabs.count > 0 {
            let tabc = PannableTabBarController(orientations: orientations)

            var pages = [UINavigationController]()
            for (idx, ele) in tabs.enumerated() {
                let page = UINavigationController(rootViewController: MiniPageViewController(app: appInfo, page: ele.path, title: ele.title, isRoot: true))
                page.tabBarItem = UITabBarItem(title: ele.title, image: UIImage(systemName: ele.systemImage), tag: idx)
                pages.append(page)
            }
            tabc.viewControllers = pages

            if let tc = appInfo.tintColor {
                let tint = UIColor(hexOrCSSName: tc)
                for ele in pages {
                    ele.navigationBar.tintColor = tint
                }
                tabc.tabBar.tintColor = tint
            }

            vc = tabc
        } else {
            let nvc = PannableNavigationViewController(rootViewController: MiniPageViewController(app: appInfo, isRoot: true), orientations: orientations)
            if let tc = appInfo.tintColor {
                nvc.navigationBar.tintColor = UIColor(hexOrCSSName: tc)
            }
            vc = nvc
        }

        if appInfo.colorScheme == "dark" {
            vc.overrideUserInterfaceStyle = .dark
        } else if appInfo.colorScheme == "light" {
            vc.overrideUserInterfaceStyle = .light
        }

        return vc
    }

    func openMiniApp(parent: UIViewController, window: UIWindow? = nil, appInfo: AppInfo, animated: Bool = true, completion: (() -> Void)? = nil) {
        let app = appInfo

        Task {
            var addr = ""
            if app.webServerEnabled == true {
                var server: HTTPServer
                if self.httpServer == nil {
                    server = HTTPServer(address: try! .inet(ip4: "127.0.0.1", port: 60008), logger: LoggerForFlyingFox())
                    self.httpServer = server
                    let fileManager = FileManager.default
                    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

                    let dirHandler = DirectoryHTTPHandler(root: documentsURL)
                    await server.appendRoute("GET /*") { req in
                        var _req: HTTPRequest = req
                        guard let appName = MiniAppManager.shared.openedApp?.name else {
                            return HTTPResponse(statusCode: .notFound)
                        }
                        _req.path = "/\(appName)" + req.path
                        do {
                            return try await dirHandler.handleRequest(_req)
                        } catch {
                            return HTTPResponse(statusCode: .notFound)
                        }
                    }

                    await server.appendRoute("POST /closeApp") { _ in
                        DispatchQueue.main.async {
                            if let mvc = getTopViewController() as? MiniPageViewController {
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
                        } catch {}
                        return HTTPResponse(statusCode: .ok, body: res)
                    }
                } else {
                    server = self.httpServer!
                }

                Task {
                    if await !server.isListening {
                        try? await server.run()
                    }
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
                    self.serverAddress = addr
                }
            }

            let vc = await self.createMiniAppRootViewController(appInfo: appInfo)

            await MainActor.run {
                vc.modalPresentationStyle = .fullScreen
                MiniAppManager.shared.openedApp = appInfo
            }

            if appInfo.orientation == "landscape" {
                await MainActor.run {
                    vc.modalPresentationStyle = .fullScreen
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
}
