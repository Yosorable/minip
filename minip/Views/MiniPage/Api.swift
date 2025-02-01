//
//  Api.swift
//  minip
//
//  Created by LZY on 2024/3/5.
//

import Foundation
import SafariServices
import AVFoundation
import AVKit
import PKHUD
import ZLPhotoBrowser
import SwiftUI
import LocalAuthentication

struct AlertAction: Codable {
    var title: String?
    var style: String?
    var key: String // 回调参数
}

struct AlertConfig: Codable {
    var title: String?
    var message: String?
    var preferredStyle: String?
    var actions: [AlertAction]
}

extension MiniPageViewController {
    func register() {
        // navigate
        bridge.register(handlerName: "close") { [weak self] (parameters, callback) in
            self?.close()
            callback?(true)
        }
        
        bridge.register(handlerName: "showAppDetail") { [weak self] (parameters, callback) in
            self?.showAppDetail()
            callback?(true)
        }
        
        bridge.register(handlerName: "navigateTo") { [weak self] (parameters, callback) in
            let _newPage = parameters?["page"] as? String
            let title = parameters?["title"] as? String
            if let newPage = _newPage {
                guard let app = self?.app  else {
                    callback?(false)
                    return
                }
                let vc = MiniPageViewController(app: app, page: newPage, title: title)
                if self?.isRoot == true {
                    vc.hidesBottomBarWhenPushed = true
                }
                self?.navigationController?.pushViewController(vc, animated: true)
                callback?(true)
                return
            }
            callback?(false)
        }
        
        bridge.register(handlerName: "navigateBack") { [weak self] (_, _) in
            if (self?.navigationController?.topViewController == self) {
                self?.navigationController?.popViewController(animated: true)
            }
        }
        
        bridge.register(handlerName: "openWeb") { [weak self] (parameters, callback) in
            guard let urlStr = parameters?["url"] as? String else {
                callback?(false)
                return
            }

            guard let url = URL(string: urlStr) else {
                callback?(false)
                return
            }
            let safariVC = SFSafariViewController(url: url)
            self?.present(safariVC, animated: true)
            callback?(true)
        }

        // refresh
        bridge.register(handlerName: "enableRefreshControl") { [weak self] (parameters, callback) in
            self?.addRefreshControl()
            callback?(true)
        }

        bridge.register(handlerName: "disableRefreshControl") { [weak self] (parameters, callback) in
            guard let rf = self?.refreshControl else {
                callback?(true)
                return
            }
            self?.refreshControl?.endRefreshing()
            self?.refreshControl = nil
            rf.removeFromSuperview()
            callback?(true)
        }

        bridge.register(handlerName: "startRefresh") { [weak self] (parameters, callback) in
            self?.refreshControl?.beginRefreshing()
            callback?(true)
        }

        bridge.register(handlerName: "endRefresh") { [weak self] (parameters, callback) in
            self?.refreshControl?.endRefreshing()
            callback?(true)
        }

        // video
        bridge.register(handlerName: "playVideo") { [weak self] (parameters, callback) in
            guard let urlStr = parameters?["url"] as? String else {
                callback?(false)
                return
            }

            guard let url = URL(string: urlStr) else {
                callback?(false)
                return
            }

            let player = AVPlayer(url: url)
            let playerViewController = AVPlayerViewController()
            playerViewController.player = player
            self?.present(playerViewController, animated: true) {
                playerViewController.player?.play()
            }
            callback?(true)
        }

        // file
        // todo: 性能差
        bridge.register(handlerName: "writeFile") { [weak self] (parameters, callback) in
            
            guard let fileName = parameters?["filename"] as? String,
                  let data = parameters?["data"] as? [UInt8],
                  let app = self?.app,
                  let pageURL = self?.pageURL
            else {
                callback?(false)
                return
            }
            
            
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appDirURL = documentsURL.appendingPolyfill(path: app.name)
            var targetFileURL: URL
            if fileName.isEmpty || !fileName.hasPrefix("/") {
                targetFileURL = pageURL.deletingLastPathComponent().appendingPathComponent(fileName)
            } else {
                targetFileURL = appDirURL.appendingPathComponent(fileName)
            }
            
            guard let f = targetFileURL.path.splitPolyfill(separator: documentsURL.lastPathComponent).last else {
                callback?(false)
                return
            }
            if !WriteToFile(data: Data(data), fileName: String(f)) {
                callback?(false)
                return
            }
            callback?(true)
        }
        
        // todo: 性能太差，32MB的文件卡顿太久
        bridge.register(handlerName: "readFile") { [weak self] (parameters, callback) in
            
            guard let fileName = parameters?["filename"] as? String,
                  let app = self?.app,
                  let pageURL = self?.pageURL
            else {
                callback?([UInt8]())
                return
            }
            
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appDirURL = documentsURL.appendingPolyfill(path: app.name)
            var targetFileURL: URL
            if fileName.isEmpty || !fileName.hasPrefix("/") {
                targetFileURL = pageURL.deletingLastPathComponent().appendingPathComponent(fileName)
            } else {
                targetFileURL = appDirURL.appendingPathComponent(fileName)
            }
            
            guard let f = targetFileURL.path.splitPolyfill(separator: documentsURL.lastPathComponent).last else {
                callback?([UInt8]())
                return
            }
            
            let dt = readFile(fileName: String(f))
            callback?(dt)
        }
        bridge.register(handlerName: "listFiles") { [weak self] (parameters, callback) in
            guard let path = parameters?["path"] as? String, let app = self?.app, let pageURL = self?.pageURL else {
                callback?([String]())
                return
            }
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appDirURL = documentsURL.appendingPolyfill(path: app.name)
            var dir: URL
            if path.isEmpty || !path.hasPrefix("/") {
                dir = pageURL.deletingLastPathComponent().appendingPolyfill(path: path)
            } else {
                dir = appDirURL.appendingPolyfill(path: path)
            }
            
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                var res = [String]()
                fileURLs.forEach { ele in
                    guard let f = ele.path.splitPolyfill(separator: app.name).last else {
                        return
                    }
                    res.append(String(f))
                }
                callback?(res)
            } catch let error {
                logger.error("[register] listFiles error: \(error.localizedDescription)")
                callback?([String]())
            }
        }
        
        // hud
        bridge.register(handlerName: "HUD") { (parameters, callback) in
            /*
             type: String (success, error, progress, label)
             title?: String
             subTitle?: String
             delay?: Float (second)
             */
            guard var type = parameters?["type"] as? String else {
                callback?(false)
                return
            }
            let title = parameters?["title"] as? String
            let subTitle = parameters?["subTitle"] as? String
            let delay = parameters?["delay"] as? Double
            
            var contentType: HUDContentType?
            
            type = type.lowercased()
            if type == "success" {
                contentType = .labeledSuccess(title: title, subtitle: subTitle)
            } else if type == "error" {
                contentType = .labeledError(title: title, subtitle: subTitle)
            } else if type == "progress" {
                contentType = .labeledProgress(title: title, subtitle: subTitle)
            } else if type == "label" {
                if title == nil && subTitle == nil {
                    return
                } else if subTitle == nil {
                    contentType = .label(title)
                } else if title == nil {
                    contentType = .label(subTitle)
                } else {
                    contentType = .label("\(title ?? "")\n\(subTitle ?? "")")
                }
            }
            
            guard let ct = contentType else {
                callback?(false)
                return
            }
            if let d = delay {
                HUD.flash(ct, delay: d) { res in
                    callback?(res)
                }
            } else {
                HUD.flash(ct, delay: 0.5) { res in
                    callback?(res)
                }
            }
            
        }
        
        bridge.register(handlerName: "previewImage") { (parameters, callback) in
            guard let urlStr = parameters?["url"] as? String else {
                callback?(false)
                return
            }
            guard let url = URL(string: urlStr) else {
                callback?(false)
                return
            }
            PreviewImage(url: url)
            callback?(true)
            return
        }
        
        // data
        bridge.register(handlerName: "setMemStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String, let val = parameters?["val"] as? String else {
                callback?(false)
                return
            }
            MiniAppManager.shared.appTmpStore[key] = val
            callback?(true)
        }
        bridge.register(handlerName: "getMemStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            let val = MiniAppManager.shared.appTmpStore[key]
            callback?(val)
        }
        bridge.register(handlerName: "delMemStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            MiniAppManager.shared.appTmpStore.removeValue(forKey: key)
            callback?(true)
        }
        
        // persisent data
        bridge.register(handlerName: "setKVStore") { [weak self] (parameters, callback) in
            guard let key = parameters?["key"] as? String, let val = parameters?["val"] as? String else {
                callback?(false)
                return
            }
            guard let appId = MiniAppManager.shared.openedApp?.appId else {
                callback?(false)
                return
            }
            do {
                try KVStoreManager.shared.getDB(dbName: appId)?.put(value: val, forKey: key)
                callback?(true)
                // observed data
                if let wids = MiniAppManager.shared.observedData[key], let that = self {
                    var waitToSendWIDs = [Int]()
                    wids.forEach {id in
                        if id == that.webview.id {
                            return
                        }
                        waitToSendWIDs.append(id)
                    }
                    var data = [String: String]()
                    data["key"] = key
                    data["value"] = val
                    
                    let encoder = JSONEncoder()
                    let dataStr = String(data: try! encoder.encode(data))!

                    MWebViewPool.shared.visiableWebViewSet.forEach { wv in
                        if (waitToSendWIDs.contains(wv.id!)) {
                            wv.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"observedDataChanged\", {\"detail\": \(dataStr)}))")
                        }
                    }
                }
                
                
            } catch let error {
                logger.error("[register] \(error.localizedDescription)")
                callback?(false)
            }
        }
        
        bridge.register(handlerName: "getKVStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            guard let appId = MiniAppManager.shared.openedApp?.appId else {
                callback?(nil)
                return
            }
            do {
                let res = try KVStoreManager.shared.getDB(dbName: appId)?.get(type: String.self, forKey: key)
                callback?(res)
            } catch let error {
                logger.error("[register] \(error.localizedDescription)")
                callback?(nil)
            }
        }
        
        bridge.register(handlerName: "delKVStore") { [weak self] (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            guard let appId = MiniAppManager.shared.openedApp?.appId else {
                callback?(nil)
                return
            }
            do {
                try KVStoreManager.shared.getDB(dbName: appId)?.deleteValue(forKey: key)
                callback?(true)
                
                if let wids = MiniAppManager.shared.observedData[key], let that = self {
                    var waitToSendWIDs = [Int]()
                    wids.forEach {id in
                        if id == that.webview.id {
                            return
                        }
                        waitToSendWIDs.append(id)
                    }
                    var data = [String: String?]()
                    data["key"] = key
                    data["value"] = nil
                    
                    let encoder = JSONEncoder()
                    let dataStr = String(data: try! encoder.encode(data))!

                    MWebViewPool.shared.visiableWebViewSet.forEach { wv in
                        if (waitToSendWIDs.contains(wv.id!)) {
                            wv.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"observedDataChanged\", {\"detail\": \(dataStr)}))")
                        }
                    }
                }
            } catch let error {
                logger.error("[register] \(error.localizedDescription)")
                callback?(false)
            }
        }
        
        bridge.register(handlerName: "getSafeAreaInsets") { (parameters, callback) in
            var res = ["top": 0.0, "left": 0.0, "bottom": 0.0, "right": 0.0]
            guard let insets = UIApplication.shared.windows.first?.safeAreaInsets else {
                callback?(res)
                return
            }
            res["top"] = insets.top
            res["left"] = insets.left
            res["bottom"] = insets.bottom
            res["right"] = insets.right
            callback?(res)
        }
        
        bridge.register(handlerName: "alert") { [weak self] (params, callback) in
            if self == nil {
                callback?(nil)
                return
            }
            guard let cfg = (params?["config"] as? String)?.data(using: .utf8) else {
                callback?(nil)
                return
            }
            let decoder = JSONDecoder()
            guard let config = try? decoder.decode(AlertConfig.self, from: cfg) else {
                callback?(nil)
                return
            }
            let alert = UIAlertController(title: config.title, message: config.message, preferredStyle: config.preferredStyle == "actionSheet" ? .actionSheet : .alert)
            config.actions.forEach { act in
                var style = UIAlertAction.Style.default
                if act.style == "cancel" {
                    style = .cancel
                } else if act.style == "destructive" {
                    style = .destructive
                }
                alert.addAction(UIAlertAction(title: act.title, style: style) { _ in
                    callback?(act.key)
                })
            }
            alert.view.tintColor = self!.view.tintColor
            
            if let ppc = alert.popoverPresentationController {
                ppc.sourceView = self!.view
                ppc.sourceRect = CGRectMake(self!.view.bounds.size.width / 2.0, self!.view.bounds.size.height / 2.0, 1.0, 1.0)
            }
            self!.present(alert, animated: true, completion: nil)
        }

        bridge.register(handlerName: "shortShake") { params, _ in
            let type = params?["type"] as? String
            var generator = UIImpactFeedbackGenerator(style: .medium)
            if type == "light" {
                generator = UIImpactFeedbackGenerator(style: .light)
            } else if type == "medium" {
                generator = UIImpactFeedbackGenerator(style: .medium)
            } else if type == "heavy" {
                generator = UIImpactFeedbackGenerator(style: .heavy)
            }
            generator.impactOccurred()
        }
        
        // device
        bridge.register(handlerName: "localAuthentication") { (_, callback) in
            let context = LAContext()
            var error: NSError?
            
            if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
                let reason = "Identify yourself!"
                
                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                    success, authenticationError in
                    
                    DispatchQueue.main.async {
                        if success {
                            callback?(true)
                        } else {
                            callback?(false)
                        }
                    }
                }
            } else {
                callback?(nil)
            }
        }
        
        bridge.register(handlerName: "setObservableData") { [weak self] (params, callback) in
            logger.debug("[register] setObservableData")
            guard let key = params?["key"] as? String else {
                callback?(nil)
                return
            }
            let initValue = (params?["initValue"] as? String) ?? ""
            
            guard let appId = MiniAppManager.shared.openedApp?.appId else {
                callback?(false)
                return
            }
            
            do {
                let res = try KVStoreManager.shared.getDB(dbName: appId)?.get(type: String.self, forKey: key)
                if let res = res {
                    callback?(res)
                } else {
                    try KVStoreManager.shared.getDB(dbName: appId)?.put(value: initValue, forKey: key)
                    callback?(initValue)
                }
                
                let wid = self?.webview.id!
                if MiniAppManager.shared.observedData[key] == nil {
                    MiniAppManager.shared.observedData[key] = Set<Int>()
                }
                MiniAppManager.shared.observedData[key]?.insert(wid!)
            } catch let error {
                logger.error("[register] \(error.localizedDescription)")
                callback?(nil)
            }
            
        }
        
        bridge.register(handlerName: "getClipboardData") { _, callback in
            if let txt = UIPasteboard.general.string {
                callback?(txt)
                return
            }
            callback?(nil)
        }
        
        
        bridge.register(handlerName: "setClipboardData") { params, callback in
            guard let data = params?["data"] as? String else {
                callback?(false)
                return
            }
            UIPasteboard.general.string = data
            callback?(true)
        }
        
        
        bridge.register(handlerName: "hideNavigationBar") { [weak self] params, _ in
            self?.navigationController?.setNavigationBarHidden(true, animated: true)
        }
        
        bridge.register(handlerName: "showNavigationBar") { [weak self] params, _ in
            self?.navigationController?.setNavigationBarHidden(false, animated: true)
        }
        
        // sqlite
        bridge.register(handlerName: "sqliteOpen") { [weak self] params, callback in
            guard let path = params?["path"] as? String else {
                callback?(false)
                logger.error("[sqliteOpen] path error")
                return
            }
            guard let self = self else {
                callback?(false)
                logger.error("[sqliteOpen] deinited")
                return
            }

            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let appDirURL = documentsURL.appendingPolyfill(path: app.name)
            let targetFileURL: URL = appDirURL.appendingPathComponent(path)
            let key = targetFileURL.path
            if MiniAppManager.shared.openedDatabase.keys.contains(key) {
                callback?(key)
                logger.info("[sqliteOpen] already opened")
                return
            }
            
            let db = SQLiteDatabase()
            if !db.open(databasePath: key) {
                callback?(false)
                logger.error("[sqliteOpen] open or create db error at [\(key)]")
                return
            }
            MiniAppManager.shared.openedDatabase[key] = db
            logger.info("[sqliteOpen] open db at [\(key)]")
            callback?(key)
        }
        
        bridge.register(handlerName: "sqliteClose") { params, callback in
            guard let path = params?["path"] as? String else {
                callback?(false)
                logger.error("[sqliteClose] path error")
                return
            }
            let key = path
            
            if let db = MiniAppManager.shared.openedDatabase.removeValue(forKey: key) {
                db.close()
                callback?(true)
                logger.info("[sqliteClose] close db at [\(key)]")
                return
            }
            callback?(false)
        }
        
        bridge.register(handlerName: "sqliteExecute") { params, callback in
            guard let path = params?["path"] as? String else {
                callback?(false)
                logger.error("[sqliteExecute] path error")
                return
            }
            let key = path
            guard let sql = params?["sql"] as? String else {
                callback?(false)
                logger.error("[sqliteExecute] sql error")
                return
            }
            guard let db = MiniAppManager.shared.openedDatabase[key] else {
                callback?(false)
                logger.error("[sqliteExecute] db not open at [\(key)]")
                return
            }
            do {
                let sqlRes = try db.executeQuery(sql: sql)
                var res = [String:Any]()
                res["code"] = 7
                res["data"] = sqlRes
                logger.info("[sqliteExecute] excute sql success at [\(key)]")
                callback?(res)
            } catch {
                logger.error("[sqliteExecute] fail to excute sql at [\(key)]")
            }
        }
        
        // 以下为测试api
        bridge.register(handlerName: "selectPhoto") { [weak self] (parameters, callback) in
            if self == nil {
                callback?(false)
                return
            }
            let ps = ZLPhotoPreviewSheet()
            let config = ZLPhotoConfiguration.default()
            config.allowTakePhotoInLibrary = parameters?[""] as? Bool ?? true
            config.allowSelectVideo = parameters?[""] as? Bool ?? false
            config.allowSelectImage = parameters?[""] as? Bool ?? true
            config.allowSelectOriginal = parameters?[""] as? Bool ?? false
            config.maxSelectCount = parameters?[""] as? Int ?? 1
            
            ps.selectImageBlock = { results, isOriginal in
                guard !results.isEmpty else {
                    callback?(false)
                    return
                }
                let assets = results
                let asset = assets[0].asset
                if asset.mediaType == .image, let imgData = assets[0].image.pngData() {
                    var images: [UIImage] = []
                    for ele in assets {
                        images.append(ele.image)
                    }
                    
                    let docURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                    let path = docURL.appendingPolyfill(path: "tmp").appendingPathComponent(UUID().uuidString, conformingTo: .png)

                    try? imgData.write(to: path)
                    callback?([path.absoluteString])
                    return
                }
                callback?(false)
            }
            ps.showPhotoLibrary(sender: self!)
        }
        
        bridge.register(handlerName: "ping") { (parameters, callback) in
            var res = "pong"
            if let data = parameters?["data"] as? String {
                res += " " + data
            }
            callback?(res)
        }
        
        // install app
        // todo: permission control !!!
        bridge.register(handlerName: "installApp") { (parameters, callback) in
            guard let url = parameters?["url"] as? String  else {
                callback?(ApiUtils.makeFailedRes(msg: "Error format of url"))
                return
            }
            DownloadMiniAppPackageToTmpFolder(url, onError: { err in
                callback?(false)
            }, onSuccess: { pkgURL in
                InstallMiniApp(pkgFile: pkgURL, onSuccess: {
                    callback?(true)
                }, onFailed: {msg in
                    callback?(false)
                })
            })
        }
    }
}
