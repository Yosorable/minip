//
//  MiniPageViewController.swift
//  minip
//
//  Created by ByteDance on 2023/8/5.
//

import AVFoundation
import AVKit
import Kingfisher
import OSLog
import SafariServices
import SwiftUI
import UIKit
import WebKit

class MiniPageViewController: UIViewController {
    var webview: MWebView!
    let project: InstalledProject
    var app: AppInfo {
        project.appInfo
    }
    var page: String
    var _title: String?
    var pageURL: URL?
    var refreshControl: UIRefreshControl?
    var initialTouchPoint: CGPoint = .init(x: 0, y: 0)
    var isRoot: Bool

    var capsuleMoreButton: UIView?

    init(project: InstalledProject, page: String? = nil, title: String? = nil, isRoot: Bool = false) {
        self.project = project
        self.page = page ?? project.appInfo.homepage
        _title = title ?? project.appInfo.title
        self.isRoot = isRoot
        super.init(nibName: nil, bundle: nil)
    }

    private func localPageURL(for page: String, rootURL: URL) -> URL {
        let relativePage = page.hasPrefix("/") ? String(page.dropFirst()) : page
        let baseURL = URL(fileURLWithPath: rootURL.path, isDirectory: true)
        return URL(string: relativePage, relativeTo: baseURL)?.absoluteURL
            ?? baseURL.appendingPathComponent(relativePage)
    }

    func redirectTo(page pg: String, title t: String? = nil) {
        page = pg
        if let t = t {
            title = t
        }
        var url: URL
        // TODO: Relative path like (based on previous page)
        if page.hasPrefix("http://") || page.hasPrefix("https://") {
            url = URL(string: page)!
            logger.info("[webview] load remote: \(url)")
            let req = URLRequest(url: url)
            webview.load(req)
        } else if app.webServerEnabled == true, let addr = MiniAppManager.shared.serverAddress {
            if !page.starts(with: "/") {
                page = "/" + page
            }
            url = URL(string: addr + "\(page)")!
            logger.info("[webview] load localhost: \(url)")
            let req = URLRequest(url: url)
            webview.load(req)
        } else {
            let rootURL = project.rootURL
            url = localPageURL(for: page, rootURL: rootURL)
            logger.info("[webview] load file: \(url)")
            webview.loadFileURL(url, allowingReadAccessTo: rootURL)
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
            self.webview.configuration.preferences.isTextInteractionEnabled = true
            self.webview.uiDelegate = nil
            self.webview.navigationDelegate = nil
            self.webview.scrollView.showsVerticalScrollIndicator = true
            self.webview.scrollView.showsHorizontalScrollIndicator = true
            self.webview.scrollView.bounces = true
            self.webview.scrollView.verticalScrollIndicatorInsets = .zero
            self.webview.scrollView.horizontalScrollIndicatorInsets = .zero

            MWebViewPool.shared.recycleReusedWebView(self.webview)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // TODO: why nil?
        if MiniAppManager.shared.openedProject == nil {
            MiniAppManager.shared.openedProject = project
        }

        setupAppLifecycleObservers()

        let showNav = app.navigationBarStatus != "hidden"

        webview = MWebViewPool.shared.getReusedWebView(forHolder: self)
        webview.uiDelegate = self
        webview.navigationDelegate = self
        if #available(iOS 16.4, *) {
            webview.isInspectable = Preferences.wkwebviewInspectable
        }

        if app.iOS_disableTextInteraction == true {
            webview.configuration.preferences.isTextInteractionEnabled = false
        } else {
            webview.configuration.preferences.isTextInteractionEnabled = true
        }

        view.addSubview(webview)
        webview.translatesAutoresizingMaskIntoConstraints = false

        if app.alwaysInSafeArea == true {
            if showNav {
                let appearance = UINavigationBarAppearance()
                appearance.backgroundEffect = .none
                appearance.shadowColor = .clear
                navigationController?.navigationBar.standardAppearance = appearance
                navigationController?.navigationBar.scrollEdgeAppearance = appearance
                navigationController?.navigationBar.compactAppearance = appearance
                navigationController?.navigationBar.compactScrollEdgeAppearance = appearance
            }
            NSLayoutConstraint.activate([
                webview.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
                webview.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
                webview.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
                webview.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            ])
        } else {
            NSLayoutConstraint.activate([
                webview.topAnchor.constraint(equalTo: view.topAnchor),
                webview.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                webview.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                webview.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            ])
        }

        if let bc = app.backgroundColor {
            view.backgroundColor = UIColor(hexOrCSSName: bc)
            webview.backgroundColor = UIColor(hexOrCSSName: bc)
        } else {
            view.backgroundColor = .systemBackground
            webview.backgroundColor = .systemBackground
        }

        if app.iOS_scrollbar?.hide == true {
            webview.scrollView.showsVerticalScrollIndicator = false
            webview.scrollView.showsHorizontalScrollIndicator = false
            webview.scrollView.bounces = false
        } else if let scrollBarConfig = app.iOS_scrollbar {
            webview.scrollView.verticalScrollIndicatorInsets = scrollBarConfig.verticalInsets?.toUIEdgeInsets() ?? .zero
            webview.scrollView.horizontalScrollIndicatorInsets = scrollBarConfig.horizontalInsets?.toUIEdgeInsets() ?? .zero
            webview.scrollView.bounces = !(scrollBarConfig.disableBounces ?? false)
        }

        var url: URL
        // TODO: Relative path like (based on previous page)
        if page.hasPrefix("http://") || page.hasPrefix("https://") {
            url = URL(string: page)!
            logger.info("[webview] load remote: \(url)")
            let req = URLRequest(url: url)
            webview.load(req)
        } else if app.webServerEnabled == true, let addr = MiniAppManager.shared.serverAddress {
            if !page.starts(with: "/") {
                page = "/" + page
            }
            url = URL(string: addr + "\(page)")!
            logger.info("[webview] load localhost: \(url)")
            let req = URLRequest(url: url)
            webview.load(req)
        } else {
            let rootURL = project.rootURL
            url = localPageURL(for: page, rootURL: rootURL)
            logger.info("[webview] load file: \(url)")
            webview.loadFileURL(url, allowingReadAccessTo: rootURL)
        }
        pageURL = url

        title = _title ?? project.title

        if let tc = app.tintColor {
            navigationController?.navigationBar.tintColor = UIColor(hexOrCSSName: tc)
            webview.tintColor = UIColor(hexOrCSSName: tc)
        }

        if app.iOS_disableSwipeBackGesture == true {
            navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        }

        if showNav {
            if #available(iOS 26.0, *) {
                navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(close)
                    ),
                    UIBarButtonItem(
                        image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(showAppDetail)
                    ),
                ]
            } else if !Preferences.useCapsuleButton {
                navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(
                        image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(close)
                    ),
                    UIBarButtonItem(
                        image: UIImage(systemName: "ellipsis"), style: .plain, target: self, action: #selector(showAppDetail)
                    ),
                ]
            } else {
                let moreButton = UIButton(type: .system)
                moreButton.setImage(UIImage(named: "capsule-more"), for: .normal)
                moreButton.addTarget(self, action: #selector(showAppDetail), for: .touchUpInside)

                capsuleMoreButton = moreButton

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
                    closeButton.heightAnchor.constraint(equalToConstant: 96 / 3),
                ])

                navigationItem.rightBarButtonItems = [
                    UIBarButtonItem(customView: stackView)
                ]
            }
        } else {
            navigationController?.setNavigationBarHidden(true, animated: false)
            webview.scrollView.contentInsetAdjustmentBehavior = .never
        }

        adaptColorScheme()

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

    // MARK: - App Page Lifecycle Events

    private func dispatchPageEvent(_ name: String, reason: String, isAppClosing: Bool? = nil) {
        var detail = "reason: \"\(reason)\""
        if let isAppClosing {
            detail += ", isAppClosing: \(isAppClosing)"
        }
        webview.evaluateJavaScript(
            "window.dispatchEvent(new CustomEvent(\"\(name)\", { detail: { \(detail) } }))"
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        dispatchPageEvent("appPageShow", reason: "show")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        let isAppClosing = MiniAppManager.shared.isClosingApp
        if isMovingFromParent || isAppClosing {
            dispatchPageEvent("appPageHide", reason: "destroy", isAppClosing: isAppClosing)
        } else {
            dispatchPageEvent("appPageHide", reason: "hide")
        }
    }

    private func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    @objc private func appDidEnterBackground() {
        dispatchPageEvent("appPageHide", reason: "background")
    }

    @objc private func appWillEnterForeground() {
        dispatchPageEvent("appPageShow", reason: "foreground")
    }

    // MARK: - Refresh Control

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
        MiniAppManager.shared.isClosingApp = true
        dismiss(
            animated: true,
            completion: {
                logger.info("[MiniPageViewController] clear open app info & reset orientation")
                if MiniAppManager.shared.openedApp?.orientation == "landscape" {
                    let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                    windowScene?.requestGeometryUpdate(.iOS(interfaceOrientations: .all))
                }
                MiniAppManager.shared.clearOpenedApp()
            })
    }
    @objc
    func showAppDetail() {
        let detailVC = AppDetailViewController(
            project: project,
            reloadPageFunc: { [weak self] in
                self?.webview.reload()
            }, parentVC: self)

        detailVC.modalPresentationStyle = .pageSheet
        if let sheet = detailVC.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.selectedDetentIdentifier = .medium
            sheet.prefersGrabberVisible = true
            sheet.prefersEdgeAttachedInCompactHeight = true
        }
        present(detailVC, animated: true)
    }
}
