//
//  MWebViewPool.swift
//  minip
//
//  Created by LZY on 2023/11/1.
//

import OSLog
import UIKit
import WebKit

protocol MWebViewPoolProtocol: AnyObject {
    func webviewWillLeavePool()
    func webviewWillEnterPool()
}

public class MWebViewPool: NSObject {
    private let processPool = WKProcessPool()

    // webviews be owned by viewcontrollers
    public var visiableWebViewSet = Set<MWebView>()
    // webviews in recycle pool
    public var reusableWebViewSet = Set<MWebView>()

    public var counter = 0

    fileprivate let lock = DispatchSemaphore(value: 1)

    public static let shared = MWebViewPool()

    override public init() {
        super.init()
        // observe memory warnning, clear reuse pool
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarningNotification),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
        // main controller inited
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mainControllerInit),
                                               name: .mainControllerInitSuccess,
                                               object: nil)
        logger.debug("[MWebViewPool] init pool")
    }

    deinit {
        // clear set
    }
}

// MARK: Observers

extension MWebViewPool {
    @objc func mainControllerInit() {
        logger.debug("[MWebViewPool] mainControllerInit, prepare reuse webview")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.25) {
            self.prepareReuseWebView()
        }
    }

    @objc fileprivate func didReceiveMemoryWarningNotification() {
        lock.wait()
        reusableWebViewSet.removeAll()
        lock.signal()
    }
}

// MARK: Assistant

extension MWebViewPool {
    func createNewWebvew() -> MWebView {
        logger.debug("[MWebViewPool] create new")
        let cfg = MWebView.defaultConfiguration()
        cfg.processPool = processPool
        cfg.setURLSchemeHandler(MinipRequest.shared, forURLScheme: "miniphttp")
        cfg.setURLSchemeHandler(MinipRequest.shared, forURLScheme: "miniphttps")

        cfg.setURLSchemeHandler(MinipImage.shared, forURLScheme: "minipimghttp")
        cfg.setURLSchemeHandler(MinipImage.shared, forURLScheme: "minipimghttps")

        cfg.setURLSchemeHandler(MinipURLSchemePing(), forURLScheme: "minipping")
        cfg.userContentController.addScriptMessageHandler(MinipNativeInteraction(), contentWorld: .page, name: MinipNativeInteraction.name)

        let webview = MWebView(frame: CGRect.zero, configuration: cfg)
        webview.isOpaque = false
        webview.scrollView.contentInsetAdjustmentBehavior = .always
        return webview
    }

    /// owned webView's holder is destroyed, recycle it
    func tryCompactWeakHolders() {
        lock.wait()
        let shouldReusedWebViewSet = visiableWebViewSet.filter { $0.holderObject == nil }
        for webView in shouldReusedWebViewSet {
            webView.webviewWillEnterPool()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }
        lock.signal()
    }

    func prepareReuseWebView() {
        guard reusableWebViewSet.count <= 0 else { return }
        reusableWebViewSet.insert(createNewWebvew())
    }
}

// MARK: reuse pool management

public extension MWebViewPool {
    func getReusedWebView(forHolder holder: AnyObject?) -> MWebView {
        assert(holder != nil, "MWebView holder cannot be nil")
        guard let holder = holder else {
            return createNewWebvew()
        }

        tryCompactWeakHolders()
        let webView: MWebView
        lock.wait()
        if reusableWebViewSet.count > 0 {
            logger.debug("[MWebViewPool] reuse")
            webView = reusableWebViewSet.randomElement()!
            reusableWebViewSet.remove(webView)
            visiableWebViewSet.insert(webView)

            webView.webviewWillLeavePool()
        } else {
            webView = createNewWebvew()
            visiableWebViewSet.insert(webView)
        }

        webView.holderObject = holder
        webView.id = counter
        counter += 1
        lock.signal()

        return webView
    }

    func recycleReusedWebView(_ webView: MWebView?) {
        guard let webView = webView else { return }
        logger.debug("[MWebViewPool] recycle webview")
        lock.wait()
        if visiableWebViewSet.contains(webView) {
            webView.webviewWillEnterPool()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }
        lock.signal()
    }

    func clearAllReusableWebViews() {
        lock.wait()
        for webview in reusableWebViewSet {
            webview.webviewWillEnterPool()
        }
        reusableWebViewSet.removeAll()
        lock.signal()
    }
}
