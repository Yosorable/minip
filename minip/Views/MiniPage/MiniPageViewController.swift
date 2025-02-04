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
import OSLog
import Defaults

class MiniPageViewController: UIViewController {
    var webview: MWebView!
    var bridge: WKWebViewJavascriptBridge!
    var app: AppInfo
    var page: String
    var _title: String?
    var pageURL: URL?
    var refreshControl: UIRefreshControl?
    var initialTouchPoint: CGPoint = CGPoint(x: 0, y: 0)
    var isRoot: Bool
    
    init(app: AppInfo, page: String? = nil, title: String? = nil, isRoot: Bool = false) {
        self.app = app
        self.page = page ?? app.homepage
        _title = title ?? app.title
        self.isRoot = isRoot
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
            self.webview.scrollView.contentInsetAdjustmentBehavior = .always
            
            MWebViewPool.shared.recycleReusedWebView(self.webview)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        webview = MWebViewPool.shared.getReusedWebView(forHolder: self)
        if #available(iOS 16.4, *) {
            webview.isInspectable = Defaults[.wkwebviewInspectable]
        }
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
        
        var url: URL
        if app.webServerEnabled == true, let addr = MiniAppManager.shared.serverAddress {
            if !page.starts(with: "/") {
                page = "/" + page
            }
            url = URL(string: addr + "\(page)")!
            logger.info("[webview] load \(url)")
            let req = URLRequest(url: url)
            webview.load(req)
        } else {
            url = URL(string: documentsURL.absoluteString + "\(app.name)/\(page)") ?? documentsURL.appendingPolyfill(path: "\(app.name)/\(page)")
            logger.info("[webview] load \(url)")
            webview.loadFileURL(url, allowingReadAccessTo: documentsURL)
        }
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
            if Defaults[.useCapsuleButton] {
                let moreButton = UIButton(type: .system)
                moreButton.setImage(UIImage(named: "capsule-more"), for: .normal)
                moreButton.addTarget(self, action: #selector(showAppDetail), for: .touchUpInside)

                let closeButton = UIButton(type: .system)
                closeButton.setImage(UIImage(named: "capsule-close"), for: .normal)
                closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

                let stackView = UIStackView(arrangedSubviews: [moreButton, closeButton])
                stackView.axis = .horizontal
                stackView.spacing = 0
                stackView.distribution = .equalSpacing
                
                NSLayoutConstraint.activate([
                    moreButton.widthAnchor.constraint(equalToConstant: 132 / 3),
                    moreButton.heightAnchor.constraint(equalToConstant: 96 / 3),
                    closeButton.widthAnchor.constraint(equalToConstant: 132 / 3),
                    closeButton.heightAnchor.constraint(equalToConstant: 96 / 3)
                ])

                navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(customView: stackView)
                ]
            } else {
                navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(close)
                    ),
                    UIBarButtonItem(
                        image: UIImage(systemName: "ellipsis"), style: .done, target: self, action: #selector(showAppDetail)
                    )
                ]
            }
            
            if let nc = app.navigationBarColor {
                navigationController?.navigationBar.barTintColor = UIColor(hex: nc)
            }

        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
            webview.scrollView.contentInsetAdjustmentBehavior = .never
        }

        adaptColorScheme()

        if isRoot && app.landscape != true {
            if let tabVC = tabBarController as? PannableTabBarController {
                tabVC.addPanGesture(vc: self)
            } else if let navVC = navigationController as? PannableNavigationViewController {
                navVC.addPanGesture(vc: self)
            }
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if navigationController?.isNavigationBarHidden ?? false && motion == .motionShake {
            showAppDetail()
        }
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
        super.viewDidAppear(animated)

        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"viewDidAppear\"))")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"viewDidDisappear\"))")
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
        self.dismiss(animated: true, completion: {
            logger.info("[MiniPageViewController] clear open app info & reset orientation")
            if MiniAppManager.shared.openedApp?.landscape == true {
                if #available(iOS 16.0, *) {
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                } else {
                    UIDevice.current.setValue(UIInterfaceOrientation.unknown.rawValue, forKey: "orientation")
                }
            }
            MiniAppManager.shared.clearOpenedApp()
        })
    }
    
    @objc
    func showAppDetail() {
        var closeFnc: (()->Void)?
        // 暂时停用appdetail中的关闭按钮
//        if self.navigationController?.isNavigationBarHidden ?? true {
//            closeFnc = {
//                self.close()
//            }
//        }
        
        self.presentPanModal(AppDetailViewController(appInfo: app, reloadPageFunc: {
            self.webview.reload()
        }, closeFunc: closeFnc, parentVC: self))
    }
}
