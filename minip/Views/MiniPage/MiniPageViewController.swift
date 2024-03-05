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
import SafariServices
import AVKit
import AVFoundation

class MiniPageViewController: UIViewController {
    var webview: MWebView!
    var bridge: WKWebViewJavascriptBridge!
    var app: AppInfo
    var page: String
    var _title: String?
    var pageURL: URL?
    var refreshControl: UIRefreshControl?
    
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
        if webview != nil {
            self.refreshControl?.endRefreshing()
            self.refreshControl?.removeFromSuperview()
            self.refreshControl = nil
            self.webview.tintColor = .systemBlue
            MWebViewPool.shared.recycleReusedWebView(self.webview)
            print("recycle")
        }
    }
    
    override func viewDidLoad() {
        webview = MWebViewPool.shared.getReusedWebView(forHolder: self)
        bridge = WKWebViewJavascriptBridge(webView: webview)
        register()

        self.view = webview
        
        if let bc = app.backgroundColor {
            self.view.backgroundColor = UIColor(hex: bc)
        } else {
            self.view.backgroundColor = .systemBackground
        }

        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let url = URL(string: documentsURL.absoluteString + "\(app.name)/\(page)") ?? documentsURL.appendingPolyfill(path: "\(app.name)/\(page)")
        webview.loadFileURL(url, allowingReadAccessTo: documentsURL)
        self.pageURL = url
        
        let showNav = app.navigationBarStatus == "display"
        
        self.title = _title ?? app.name
        
        
        if let tc = app.tintColor {
            navigationController?.navigationBar.tintColor = UIColor(hex: tc)
            webview.tintColor = UIColor(hex: tc)
        }
        
        if self.app.disableSwipeBackGesture == true {
            self.navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        if showNav {
            let closebtn = UIButton.init(type: .custom)
            closebtn.setImage(UIImage(named: "close-icon"), for: .normal)
            closebtn.addTarget(self, action: #selector(close), for: .touchUpInside)
            
            let morebtn = UIButton.init(type: .custom)
            morebtn.setImage(UIImage(named: "more-icon"), for: .normal)
            morebtn.addTarget(self, action: #selector(showAppDetail), for: .touchUpInside)
            
            let stackview = UIStackView.init(arrangedSubviews: [morebtn, closebtn])
            stackview.distribution = .equalSpacing
            stackview.axis = .horizontal
            stackview.alignment = .center
            stackview.spacing = 0
            
            let rightBarButton = UIBarButtonItem(customView: stackview)
            self.navigationItem.rightBarButtonItem = rightBarButton
            rightBarButton.tintColor = view.tintColor
            
            if let nc = app.navigationBarColor {
                navigationController?.navigationBar.barTintColor = UIColor(hex: nc)
            }

        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
        }
        setNavigationBarInTabbar()
        adaptColorScheme()
    }

    // color scheme change event
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        adaptColorScheme()
    }

    // wkwebview的scrollview的滚动条颜色有问题（html里面的没问题），需要手动设置
    func adaptColorScheme() {
        if self.isDarkMode {
            self.webview.scrollView.indicatorStyle = .white
        } else {
            self.webview.scrollView.indicatorStyle = .black
        }
    }

    @objc
    func refreshWebView(_ sender: UIRefreshControl) {
        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"refreshView\"))")
    }

    override func viewDidAppear(_ animated: Bool) {
        setNavigationBarInTabbar()
        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"viewDidAppear\"))")
    }

    override func viewDidDisappear(_ animated: Bool) {
        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"viewDidDisappear\"))")
    }

    func setNavigationBarInTabbar() {
        if let tabc = tabBarController {
            tabc.title = title
            tabc.navigationItem.rightBarButtonItems = navigationItem.rightBarButtonItems
        }
    }
    
    func addRefreshControl() {
        guard refreshControl == nil else {
            return
        }
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshWebView(_:)), for: UIControl.Event.valueChanged)
        webview.scrollView.addSubview(refreshControl!)
        webview.scrollView.bounces = true
    }

    @objc
    func close() {
        self.dismiss(animated: true)
        MiniAppManager.shared.clearOpenedApp()
    }
    
    @objc
    func showAppDetail() {
        self.presentPanModal(AppDetailViewController(appInfo: app, reloadPageFunc: {
            self.webview.reload()
        }))
    }
}
