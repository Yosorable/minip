//
//  MiniPageView.swift
//  minip
//
//  Created by ByteDance on 2023/7/3.
//

import SwiftUI
import WKWebViewJavascriptBridge
import WebKit
import PKHUD
import PanModal
import Kingfisher

struct MiniPageView: View {
    @StateObject var webViewManager: WebViewManager = WebViewManager()
    
    var appInfo: AppInfo
    var pageConfig: AppInfo.PageConfig
    var url: URL
    var closeApp: (()->Void)?
    init(appInfo: AppInfo, page: String? = nil, parametersJSONStr: String? = nil, closeApp: (()->Void)? = nil) {
        self.appInfo = appInfo
        
        
        let appName = appInfo.name
        let showPage = page ?? appInfo.homepage
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        pageConfig = AppInfo.PageConfig(path: showPage)
        if let pages = appInfo.pages {
            for ele in pages {
                if ele.path == showPage {
                    pageConfig = ele
                    break
                }
            }
        }
        
        url = documentsURL.appending(path: "\(appName)/\(showPage)")
        
        self.closeApp = closeApp
        
//        webViewManager = WebViewManager(pageInfo: pageConfig)
        
        print("page: \(page ?? "nil") success")
    }
    
    
    var body: some View {
        ZStack {
            let webv = WebViewWithURL(url: url, wkwebview: {
                if let bacc = pageConfig.backgroundColor ?? appInfo.backgroundColor {
                    if let c = Color(hex: bacc) {
                        webViewManager.webview.backgroundColor = UIColor(c)
                    }
                }
                return webViewManager.webview
            }())
                .edgesIgnoringSafeArea(.all)
                .onReceive(webViewManager.$isPresented, perform: { val in
                    if !val {
                        closeApp?()
                    }
                })
            
            if let showNav = appInfo.navigationBarStatus {
                if showNav == "display" {
                    let _webv = webv
                        .navigationTitle(Text(pageConfig.title ?? ""))
                        .navigationBarTitleDisplayMode(.inline)
                        .toolbar {
                            ToolbarItemGroup(placement: .navigationBarTrailing) {
                                Button {
                                    showAppDetail()
                                } label: {
                                    Image(systemName: "ellipsis")
                                }
                                Button {
                                    closeApp?()
                                } label: {
                                    Image(systemName: "xmark")
                                }
                            }
                        }
                    if let navigationBarColor = pageConfig.navigationBarColor ?? appInfo.navigationBarColor, let color = Color(hex: navigationBarColor) {
                        _webv
                            .toolbarBackground(color, for: .navigationBar)
                            .toolbarBackground(.visible, for: .navigationBar)
                    } else {
                        _webv
                    }
                } else {
                    webv
                        .toolbar(.hidden, for: .navigationBar)
                }
            } else {
                webv
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
    
    func showAppDetail() {
        guard let topViewController = GetTopViewController() else {
            return
        }
        topViewController.presentPanModal(AppDetailViewController(appInfo: appInfo))
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

class WebViewManager: ObservableObject {
    var webview: WKWebView
    var bridge: WKWebViewJavascriptBridge
    @Published var isPresented = true
    
    init() {
        print("init WebViewManager")
        webview = WKWebViewWarmUper.shared.dequeue()
//        if #available(iOS 16.4, *) {
//            webview.isInspectable = true
//        }
        bridge = WKWebViewJavascriptBridge(webView: webview)
        register()
    }
    
    deinit {
        print("deinit WebViewManager")
    }
    
    func register() {
        // navigate
        bridge.register(handlerName: "close") { [weak self] (parameters, callback) in
            self?.isPresented.toggle()
        }
        
        bridge.register(handlerName: "navigateTo") { (parameters, callback) in
            let _newPage = parameters?["page"] as? String
            if let newPage = _newPage {
                pathManager.path.append(newPage)
                callback?(true)
                return
            }
            callback?(false)
        }
        
        // file
        bridge.register(handlerName: "writeFile") { (parameters, callback) in
            
            let fileName = parameters?["filename"] as? String
            let data = parameters?["data"] as? [UInt8]
            if fileName == nil || data == nil || !WriteToFile(data: Data(data!), fileName: fileName!) {
                callback?(false)
                return
            }
            callback?(true)
        }
        bridge.register(handlerName: "readFile") { (parameters, callback) in
            let fileName = parameters?["filename"] as? String
            if fileName == nil {
                callback?([UInt8]())
                return
            }
            let dt = readFile(fileName: fileName!)
            callback?(dt)
        }
        bridge.register(handlerName: "listFiles") { (parameters, callback) in
            guard let path = parameters?["path"] as? String else {
                callback?([String]())
                return
            }
            
            let fileManager = FileManager.default
            let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
            
            do {
                let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL.appending(path: path), includingPropertiesForKeys: nil)
                var res = [String]()
                fileURLs.forEach { ele in
                    res.append(ele.absoluteString)
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




