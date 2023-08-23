//
//  MiniPageViewController.swift
//  minip
//
//  Created by ByteDance on 2023/8/5.
//

import UIKit
import WebKit
import WKWebViewJavascriptBridge
import PKHUD
import PanModal
import SwiftUI
import Kingfisher

class MiniPageViewController: UIViewController {
    var webview: WKWebView!
    var bridge: WKWebViewJavascriptBridge!
    var app: AppInfo
    var page: String
    var _title: String?
    var pageURL: URL?
    
    init(app: AppInfo, page: String? = nil, title: String? = nil) {
        self.app = app
        self.page = page ?? app.homepage
        _title = title
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        print("deinit")
    }
    
    override func viewDidLoad() {
        webview = WKWebViewWarmUper.shared.dequeue()
        bridge = WKWebViewJavascriptBridge(webView: webview)
        register()
        
        webview.scrollView.contentInsetAdjustmentBehavior = .always
        self.view = webview
        
        if let bc = app.backgroundColor {
            self.view.backgroundColor = UIColor(hex: bc)
        } else {
            self.view.backgroundColor = .systemBackground
        }

        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let url = URL(string: documentsURL.absoluteString + "\(app.name)/\(page)") ?? documentsURL.appending(path: "\(app.name)/\(page)")
        webview.loadFileURL(url, allowingReadAccessTo: documentsURL)
        self.pageURL = url
        
        let showNav = app.navigationBarStatus == "display"
        
        self.title = _title ?? app.name
        
        
        if let tc = app.tintColor {
            navigationController?.navigationBar.tintColor = UIColor(hex: tc)
            webview.tintColor = UIColor(hex: tc)
        }
        
        if showNav {
            navigationItem.rightBarButtonItems = [
                UIBarButtonItem(
                    image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(close)
                ),
                UIBarButtonItem(
                    image: UIImage(systemName: "ellipsis"), style: .done, target: self, action: #selector(showAppDetail)
                )
            ]
            
            if let nc = app.navigationBarColor {
                navigationController?.navigationBar.barTintColor = UIColor(hex: nc)
            }

        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
    }
    
    @objc
    func close() {
        self.dismiss(animated: true)
        let appId = app.appId
        pathManager.path = []
        pathManager.appTmpStore.removeAll()
        KVStoreManager.shared.removeDB(dbName: appId)
    }
    
    @objc
    func showAppDetail() {
        self.presentPanModal(AppDetailViewController(appInfo: app))
    }
    
    func register() {
        // navigate
        bridge.register(handlerName: "close") { [weak self] (parameters, callback) in
            self?.dismiss(animated: true)
        }
        
        bridge.register(handlerName: "navigateTo") { [weak self] (parameters, callback) in
            let _newPage = parameters?["page"] as? String
            let title = parameters?["title"] as? String
            if let newPage = _newPage {
                pathManager.path.append(RouteParameter(path: newPage, title: title))
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
            let appDirURL = documentsURL.appending(path: app.name)
            var targetFileURL: URL
            if fileName.isEmpty || !fileName.hasPrefix("/") {
                targetFileURL = pageURL.deletingLastPathComponent().appendingPathComponent(fileName)
            } else {
                targetFileURL = appDirURL.appendingPathComponent(fileName)
            }
            
            guard let f = targetFileURL.path(percentEncoded: false).split(separator: documentsURL.lastPathComponent).last else {
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
            let appDirURL = documentsURL.appending(path: app.name)
            var targetFileURL: URL
            if fileName.isEmpty || !fileName.hasPrefix("/") {
                targetFileURL = pageURL.deletingLastPathComponent().appendingPathComponent(fileName)
            } else {
                targetFileURL = appDirURL.appendingPathComponent(fileName)
            }
            
            guard let f = targetFileURL.path(percentEncoded: false).split(separator: documentsURL.lastPathComponent).last else {
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
            let appDirURL = documentsURL.appending(path: app.name)
            var dir: URL
            if path.isEmpty || !path.hasPrefix("/") {
                dir = pageURL.deletingLastPathComponent().appending(path: path)
            } else {
                dir = appDirURL.appending(path: path)
            }
            
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
                var res = [String]()
                fileURLs.forEach { ele in
                    guard let f = ele.path(percentEncoded: false).split(separator: app.name).last else {
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
            pathManager.appTmpStore[key] = val
            callback?(true)
        }
        bridge.register(handlerName: "getMemStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            let val = pathManager.appTmpStore[key]
            callback?(val)
        }
        bridge.register(handlerName: "delMemStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String else {
                callback?(nil)
                return
            }
            pathManager.appTmpStore.removeValue(forKey: key)
            callback?(true)
        }
        
        // persent data
        bridge.register(handlerName: "setKVStore") { (parameters, callback) in
            guard let key = parameters?["key"] as? String, let val = parameters?["val"] as? String else {
                callback?(false)
                return
            }
            guard let appId = pathManager.openedApp?.appId else {
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
            guard let appId = pathManager.openedApp?.appId else {
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
            guard let appId = pathManager.openedApp?.appId else {
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
    }
}


class AppDetailViewController: UIViewController {
    var appInfo: AppInfo
    init(appInfo: AppInfo) {
        self.appInfo = appInfo
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        panModalSetNeedsLayoutUpdate()

        var iconURL: URL?
        if let icon = appInfo.icon {
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                iconURL = URL(string: icon)
            } else {
                iconURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appending(path: appInfo.name).appending(path: icon)
            }
        }

        let subview = UIHostingController(
            rootView:
                VStack {
                    let noIconView  = Rectangle()
                        .foregroundColor(.secondary)
                        .cornerRadius(10)
                        .frame(width: 60, height: 60)
                        .shadow(radius: 5)
                    VStack {
                        if let iconURL = iconURL {
                            if iconURL.scheme == "file", let img = UIImage(contentsOfFile: iconURL.path()) {
                                Image(uiImage: img)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(10)
                                    .shadow(radius: 5)
                            } else if iconURL.scheme == "http" || iconURL.scheme == "https" {
                                KFImage(iconURL)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 60, height: 60)
                                    .clipped()
                                    .cornerRadius(10)
                                    .background {
                                        noIconView
                                    }
                            } else {
                                noIconView
                            }
                        } else {
                            noIconView
                        }
                    }
                    .padding(.top)

                    VStack {
                        Text(appInfo.name)
                            .lineLimit(1)
                            .padding(.top)
                        Spacer()
                        Text(appInfo.version ?? "v0.0.0")
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        Text("@\(appInfo.author ?? "no_author")")
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                        Text(appInfo.appId)
                            .font(.system(size: 10))
                            .lineLimit(1)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                    }
                    .frame(height: 60)
                    if let website = appInfo.website, let url = URL(string: website) {
                        Link(website, destination: url)
                            .font(.system(size: 13))
                    }
                    VStack {
                        Text(appInfo.description ?? "No description"
                        )
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    }
                    .padding(.top, 3)
                    Spacer()
                }
                .padding(.horizontal, 20)
        ).view
        guard let subview = subview else {
            return
        }

        view.addSubview(subview)


        subview.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            subview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subview.topAnchor.constraint(equalTo: view.topAnchor),
            subview.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension AppDetailViewController: PanModalPresentable {
    var panScrollable: UIScrollView? {
        return nil
    }

    var shortFormHeight: PanModalHeight {
        return .contentHeight(300)
    }

    var longFormHeight: PanModalHeight {
        return .maxHeightWithTopInset(40)
    }
}
