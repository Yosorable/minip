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
    var openedProject: InstalledProject?
    var openedApp: AppInfo? {
        openedProject?.appInfo
    }
    var isClosingApp = false
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

    func getInstalledProjects() -> [InstalledProject] {
        let start = DispatchTime.now()
        defer {
            let end = DispatchTime.now()
            let nanoTime = end.uptimeNanoseconds - start.uptimeNanoseconds
            let timeInterval = Double(nanoTime) / 1_000_000
            logger.debug("[getInstalledProjects] cost \(timeInterval) ms")
        }
        var projects: [InstalledProject] = []
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            let decoder = JSONDecoder()
            for ele in fileURLs {
                let infoURL = ele.appendingPathComponent("app", conformingTo: .json)
                if ele.lastPathComponent != ".Trash", ele.lastPathComponent != ".data", ele.lastPathComponent != ".tmp", fileManager.fileExists(atPath: infoURL.path) {
                    do {
                        let data = try Data(contentsOf: infoURL, options: .mappedIfSafe)
                        let appInfo = try? decoder.decode(AppInfo.self, from: data)
                        if let appInfo {
                            projects.append(InstalledProject(appInfo: appInfo, rootURL: ele))
                        }
                    } catch {
                        logger.error("[getInstalledProjects] \(error.localizedDescription)")
                    }
                }
            }
        } catch {
            logger.error("[getInstalledProjects] \(error.localizedDescription)")
        }

        var appIdSortListIndexMap = [String: Int]()
        let appIdSortList = Defaults[.appSortList]

        for i in 0 ..< appIdSortList.count {
            appIdSortListIndexMap[appIdSortList[i]] = i
        }

        projects.sort(by: { lhs, rhs in
            let lhsIndex = appIdSortListIndexMap[lhs.appId]
            let rhsIndex = appIdSortListIndexMap[rhs.appId]
            if let lhsIndex, let rhsIndex, lhsIndex != rhsIndex {
                return lhsIndex < rhsIndex
            } else if lhsIndex != nil, rhsIndex == nil {
                return false
            } else if lhsIndex == nil, rhsIndex != nil {
                return true
            }
            return lhs.rootURL.lastPathComponent.localizedStandardCompare(rhs.rootURL.lastPathComponent) == .orderedAscending
        })

        let newSortList = projects.map(\.appId)
        if newSortList != appIdSortList {
            Defaults[.appSortList] = newSortList
        }

        // ignore files property
        let withoutFiles = projects.map {
            var t = $0.appInfo
            t.files = nil
            return t
        }
        if withoutFiles != Defaults[.appInfoList] {
            Defaults[.appInfoList] = withoutFiles
            logger.debug("[getInstalledProjects] cache updated")
        }

        return projects
    }

    func getAppInfos() -> [AppInfo] {
        getInstalledProjects().map(\.appInfo)
    }

    func getAppInfosFromCache() -> [AppInfo] {
        return Defaults[.appInfoList]
    }

    func refreshOpenedProjectLocation() {
        guard let openedProject else { return }

        let matches = getInstalledProjects().filter { $0.appId == openedProject.appId }
        if let sameLocation = matches.first(where: { $0.rootURL == openedProject.rootURL }) {
            self.openedProject = sameLocation
        } else if matches.count == 1 {
            self.openedProject = matches[0]
        } else if matches.count > 1 {
            logger.error("[refreshOpenedProjectLocation] multiple projects share appId: \(openedProject.appId)")
        }
    }

    func getFSManager() -> FileSystemManager? {
        if self.fileSystemManager != nil {
            return self.fileSystemManager
        }

        self.fsLock.lock()
        defer { self.fsLock.unlock() }

        if self.fileSystemManager == nil, let appInfo = openedProject?.appInfo {
            self.fileSystemManager = FileSystemManager(appInfo: appInfo)
        }

        return self.fileSystemManager
    }

    func clearOpenedApp() {
        let appId = self.openedProject?.appId
        self.openedProject = nil
        self.isClosingApp = false
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
    private func createMiniAppRootViewController(project: InstalledProject) -> UIViewController {
        let appInfo = project.appInfo
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
                let page = UINavigationController(rootViewController: MiniPageViewController(project: project, page: ele.path, title: ele.title, isRoot: true))
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
            let nvc = PannableNavigationViewController(rootViewController: MiniPageViewController(project: project, isRoot: true), orientations: orientations)
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

    func openMiniApp(parent: UIViewController, window: UIWindow? = nil, project: InstalledProject, animated: Bool = true, completion: (() -> Void)? = nil) {
        let app = project.appInfo

        Task {
            var addr = ""
            if app.webServerEnabled == true {
                var server: HTTPServer
                if self.httpServer == nil {
                    server = HTTPServer(address: try! .inet(ip4: "127.0.0.1", port: 60008), logger: LoggerForFlyingFox())
                    self.httpServer = server
                    await server.appendRoute("GET /*") { req in
                        guard let projectRootURL = MiniAppManager.shared.openedProject?.rootURL else {
                            return HTTPResponse(statusCode: .notFound)
                        }
                        let dirHandler = DirectoryHTTPHandler(root: projectRootURL)
                        do {
                            return try await dirHandler.handleRequest(req)
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

            let vc = await self.createMiniAppRootViewController(project: project)

            await MainActor.run {
                vc.modalPresentationStyle = .fullScreen
                MiniAppManager.shared.openedProject = project
            }

            if app.orientation == "landscape" {
                await MainActor.run {
                    vc.modalPresentationStyle = .fullScreen
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .landscape))
                }
                try? await Task.sleep(nanoseconds: 220_000_000)
            }

            await parent.present(vc, animated: animated, completion: {
                completion?()
            })
        }
    }
}
