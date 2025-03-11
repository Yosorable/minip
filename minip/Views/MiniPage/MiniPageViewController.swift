//
//  MiniPageViewController.swift
//  minip
//
//  Created by ByteDance on 2023/8/5.
//

import AVFoundation
import AVKit
import Defaults
import Kingfisher
import OSLog
import PanModal
import SafariServices
import SwiftUI
import UIKit
import WebKit

class MiniPageViewController: UIViewController {
    var webview: MWebView!
    var app: AppInfo
    var page: String
    var _title: String?
    var pageURL: URL?
    var refreshControl: UIRefreshControl?
    var initialTouchPoint: CGPoint = .init(x: 0, y: 0)
    var isRoot: Bool

    init(app: AppInfo, page: String? = nil, title: String? = nil, isRoot: Bool = false) {
        self.app = app
        self.page = page ?? app.homepage
        _title = title ?? app.title
        self.isRoot = isRoot
        super.init(nibName: nil, bundle: nil)
    }

    func redirectTo(page pg: String, title t: String? = nil) {
        page = pg
        if let t = t {
            title = t
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
            if page.hasPrefix("http://") || page.hasPrefix("https://") {
                url = URL(string: page)!
                logger.info("[webview] load \(url)")
                let req = URLRequest(url: url)
                webview.load(req)
            } else {
                url = URL(string: documentsURL.absoluteString + "\(app.name)/\(page)") ?? documentsURL.appendingPolyfill(path: "\(app.name)/\(page)")
                logger.info("[webview] load \(url)")
                webview.loadFileURL(url, allowingReadAccessTo: documentsURL)
            }
        }
        pageURL = url
    }

    @available(*, unavailable)
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
            self.webview.translatesAutoresizingMaskIntoConstraints = true
            if #available(iOS 14.5, *) {
                self.webview.configuration.preferences.isTextInteractionEnabled = true
            }
            self.webview.uiDelegate = nil
            self.webview.navigationDelegate = nil

            MWebViewPool.shared.recycleReusedWebView(self.webview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: why nil?
        if MiniAppManager.shared.openedApp == nil {
            MiniAppManager.shared.openedApp = app
        }
        webview = MWebViewPool.shared.getReusedWebView(forHolder: self)
        webview.uiDelegate = self
        webview.navigationDelegate = self
        if #available(iOS 16.4, *) {
            webview.isInspectable = Defaults[.wkwebviewInspectable]
        }

        if #available(iOS 14.5, *) {
            if app.iOS_disableTextInteraction == true {
                webview.configuration.preferences.isTextInteractionEnabled = false
            } else {
                webview.configuration.preferences.isTextInteractionEnabled = true
            }
        }

        if app.alwaysInSafeArea == true {
            view.addSubview(webview)
            webview.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                webview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                webview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                webview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                webview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        } else {
            view = webview
        }

        if let bc = app.backgroundColor {
            view.backgroundColor = UIColor(hex: bc)
        } else {
            view.backgroundColor = .systemBackground
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
            if page.hasPrefix("http://") || page.hasPrefix("https://") {
                url = URL(string: page)!
                logger.info("[webview] load \(url)")
                let req = URLRequest(url: url)
                webview.load(req)
            } else {
                url = URL(string: documentsURL.absoluteString + "\(app.name)/\(page)") ?? documentsURL.appendingPolyfill(path: "\(app.name)/\(page)")
                logger.info("[webview] load \(url)")
                webview.loadFileURL(url, allowingReadAccessTo: documentsURL.appendingPathComponent(app.name))
            }
        }
        pageURL = url

        let showNav = app.navigationBarStatus != "hidden"

        title = _title ?? app.name

        if let tc = app.tintColor {
            navigationController?.navigationBar.tintColor = UIColor(hex: tc)
            webview.tintColor = UIColor(hex: tc)
        }

        if app.disableSwipeBackGesture == true {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
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
        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
            webview.scrollView.contentInsetAdjustmentBehavior = .never
        }

        adaptColorScheme()

        if isRoot && (app.orientation != "landscape" || app.navigationBarStatus != "hidden") {
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
        if isDarkMode {
            webview.scrollView.indicatorStyle = .white
        } else {
            webview.scrollView.indicatorStyle = .black
        }
    }

    @objc
    func refreshWebView(_ sender: UIRefreshControl) {
        webview.evaluateJavaScript("window.dispatchEvent(new CustomEvent(\"pulldownrefresh\"))")
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
        dismiss(animated: true, completion: {
            logger.info("[MiniPageViewController] clear open app info & reset orientation")
            if MiniAppManager.shared.openedApp?.orientation == "landscape" {
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
        presentPanModal(AppDetailViewController(appInfo: app, reloadPageFunc: { [weak self] in
            self?.webview.reload()
        }, parentVC: self))
    }
}
