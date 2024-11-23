//
//  MWebViewPool.swift
//  minip
//
//  Created by LZY on 2023/11/1.
//

import UIKit
import OSLog
import WebKit

protocol MWebViewPoolProtocol: AnyObject {
    func webviewWillLeavePool()
    func webviewWillEnterPool()
}

public class MWebViewPool: NSObject {
    
    private let processPool = WKProcessPool()

    // 当前有被页面持有的webview
    public var visiableWebViewSet = Set<MWebView>()
    // 回收池中的webview
    public var reusableWebViewSet = Set<MWebView>()
    
    public var counter = 0

    fileprivate let lock = DispatchSemaphore(value: 1)

    public static let shared = MWebViewPool()

    public override init() {
        super.init()
        // 监听内存警告，清除复用池
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveMemoryWarningNotification),
                                               name: UIApplication.didReceiveMemoryWarningNotification,
                                               object: nil)
        // 监听首页初始化完成
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mainControllerInit),
                                               name: NSNotification.Name("kMainControllerInitSuccessNotiKey"),
                                               object: nil)
        logger.debug("[MWebViewPool] init pool")
    }

    deinit {
        // 清除set
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
        cfg.processPool = self.processPool
        cfg.setURLSchemeHandler(MinipRequest(), forURLScheme: "miniprequest")
        
        let webview = MWebView(frame: CGRect.zero, configuration: cfg)
        webview.isOpaque = false
        webview.scrollView.contentInsetAdjustmentBehavior = .always
        return webview
    }

    /// 使用中的webView持有者已销毁，则放回可复用池中
    func tryCompactWeakHolders() {
        lock.wait()
        let shouldReusedWebViewSet = visiableWebViewSet.filter{ $0.holderObject == nil }
        for webView in shouldReusedWebViewSet {
            webView.webviewWillEnterPool()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }
        lock.signal()
    }

    /// 预备一个空的webview
    func prepareReuseWebView() {
        guard reusableWebViewSet.count <= 0 else { return }
        self.reusableWebViewSet.insert(self.createNewWebvew())
    }
}


// MARK: 复用池管理
public extension MWebViewPool {

    /// 获取可复用的webView
    func getReusedWebView(forHolder holder: AnyObject?) -> MWebView {
        assert(holder != nil, "ZXYWebView holder不能为nil")
        guard let holder = holder else {
            return self.createNewWebvew()
        }

        tryCompactWeakHolders()
        let webView: MWebView
        lock.wait()
        if reusableWebViewSet.count > 0 {
            // 缓存池中有
            logger.debug("[MWebViewPool] reuse")
            webView = reusableWebViewSet.randomElement()!
            reusableWebViewSet.remove(webView)
            visiableWebViewSet.insert(webView)
            // 出回收池前初始化
            webView.webviewWillLeavePool()
        } else {
            // 缓存池没有，创建新的
            webView = self.createNewWebvew()
            visiableWebViewSet.insert(webView)
        }

        webView.holderObject = holder
        webView.id = counter
        counter += 1
        lock.signal()

        return webView
    }

    /// 回收可复用的webView到复用池中
    func recycleReusedWebView(_ webView: MWebView?) {
        guard let webView = webView else { return }
        logger.debug("[MWebViewPool] recycle webview")
        lock.wait()
        // 存在于当前使用中，则回收
        if visiableWebViewSet.contains(webView) {
            // 进入回收池前清理
            webView.webviewWillEnterPool()
            visiableWebViewSet.remove(webView)
            reusableWebViewSet.insert(webView)
        }
        lock.signal()
    }

    /// 移除并销毁所有复用池的webView
    func clearAllReusableWebViews() {
        lock.wait()
        for webview in reusableWebViewSet {
            webview.webviewWillEnterPool()
        }
        reusableWebViewSet.removeAll()
        lock.signal()
    }
}
