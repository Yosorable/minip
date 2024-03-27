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


extension MiniPageViewController {
    func register() {
        // navigate
        bridge.register(handlerName: "close") { [weak self] (parameters, callback) in
            self?.dismiss(animated: true)
        }
        
        bridge.register(handlerName: "navigateTo") { [weak self] (parameters, callback) in
            let _newPage = parameters?["page"] as? String
            let title = parameters?["title"] as? String
            if let newPage = _newPage {
                MiniAppManager.shared.path.append(RouteParameter(path: newPage, title: title))
                guard let app = self?.app  else {
                    callback?(false)
                    return
                }
                let vc = MiniPageViewController(app: app, page: newPage, title: title)
                self?.navigationController?.pushViewController(vc, animated: true)
                callback?(true)
                return
            }
            callback?(false)
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
                print("listFiles error: \(error.localizedDescription)")
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
        
        // persent data
        bridge.register(handlerName: "setKVStore") { (parameters, callback) in
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
            } catch let error {
                print(error.localizedDescription)
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
                print(error.localizedDescription)
                callback?(nil)
            }
        }
        
        bridge.register(handlerName: "delKVStore") { (parameters, callback) in
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
            } catch let error {
                print(error.localizedDescription)
                callback?(false)
            }
        }
        
        // 以下为测试api
        bridge.register(handlerName: "selectPhoto") { (parameters, callback) in
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
            ps.showPhotoLibrary(sender: self)
        }
    }
}
