//
//  MiniV2ViewController.swift
//  minip
//
//  Created by LZY on 2024/4/16.
//

import UIKit
import WebKit
import ECMASwift
import JavaScriptCore

class MiniV2Egine: NSObject, WKUIDelegate {
    static let shared = MiniV2Egine()
    
    var rootNavigationController: UINavigationController? = nil
    var Pages = [String: MiniV2ViewController]()
    var runtime: JSRuntime!
    var webviewBackend: WKWebView!
    
    var useWKWebViewBackend: Bool = false
    
    
    func launch(_ wkwv: Bool = false) {
        useWKWebViewBackend = wkwv
        if useWKWebViewBackend {
            setWKWebViewBackendRuntime()
        } else {
            setRuntime()
        }
        let page = MiniV2ViewController()
        Pages[page.id] = page
        page.title = "MiniV2"
        self.rootNavigationController = UINavigationController(rootViewController: page)
        self.rootNavigationController?.modalPresentationStyle = .fullScreen
        GetTopViewController()?.present(self.rootNavigationController!, animated: true)
    }
    
    func clear() {
        Pages.removeAll()
        runtime = nil
        if webviewBackend != nil {
            webviewBackend.uiDelegate = nil
            if #available(iOS 16.4, *) {
                webviewBackend.isInspectable = false
            }
            webviewBackend = nil
        }
    }
    
    // webview backend interact
    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        guard let dt = prompt.data(using: .utf8),
        let jsonObj = try? JSONSerialization.jsonObject(with: dt) as? [String: Any],
            let api = jsonObj["api"] as? String else {
                completionHandler(nil)
                return
            }
        if api == "callWebView" {
            if let pageId = jsonObj["pageId"] as? String,
               let script = jsonObj["script"] as? String,
               let pg = self.Pages[pageId] {
                pg.webview.evaluateJavaScript(script)
            }
            
            completionHandler(nil)
            return
        } else if api == "newPage" {
            let title = jsonObj["title"] as? String
            let newPage = MiniV2ViewController()
            newPage.title = title
            self.Pages[newPage.id] = newPage
            self.rootNavigationController?.pushViewController(newPage, animated: true)
            
            completionHandler(newPage.id)
            return
        } else if api == "_pushPage" {
            if let pageId = jsonObj["pageId"] as? String {
                let newPage = MiniV2ViewController()
                newPage.id = pageId
                newPage.title = jsonObj["title"] as? String
                self.Pages[newPage.id] = newPage
                self.rootNavigationController?.pushViewController(newPage, animated: true)
                
                completionHandler(nil)
                return
            }
        }
        completionHandler(nil)
    }
    
    func setWKWebViewBackendRuntime() {
        webviewBackend = MWebViewPool.shared.getReusedWebView(forHolder: self)
        webviewBackend.uiDelegate = self
        if #available(iOS 16.4, *) {
            webviewBackend.isInspectable = true
        }
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let name = "react-custom-render"
        let url = URL(string: documentsURL.absoluteString + "\(name)") ?? documentsURL.appendingPolyfill(path: "\(name)")
        let entry = url.appendingPathComponent("index.js")
        
        let jsFunction = """
function callWebView(pageId, script) {
    prompt(JSON.stringify({api: "callWebView", pageId, script}))
}

function newPage(title) {
    return prompt(JSON.stringify({api: "newPage", title}))
}

function _pushPage(pageId, title) {
    prompt(JSON.stringify({api: "_pushPage", pageId, title}))
}

"""
        
        let userScript = WKUserScript(source: jsFunction, injectionTime: .atDocumentStart, forMainFrameOnly: true)
        webviewBackend.configuration.userContentController.addUserScript(userScript)
        
        webviewBackend.loadHTMLString("<script>\(cat(url:entry))</script>", baseURL: nil)
        //webviewBackend.evaluateJavaScript(cat(url: entry))
    }
    
    func setRuntime() {
        runtime = JSRuntime()
        let context = runtime.context
        let callWebView: @convention(block) (String, String) -> Void = { [weak self] (pageId, script) in
            guard let pg = self?.Pages[pageId] else { return }
            pg.webview.evaluateJavaScript(script)
//            print("callwebview \(pageId)")
        }
        let newPage: @convention(block) (String?) -> String = { [weak self] title in
            if self == nil {
                return "-1"
            }
            let newPage = MiniV2ViewController()
            newPage.title = title
            self!.Pages[newPage.id] = newPage
            self?.rootNavigationController?.pushViewController(newPage, animated: true)
            return newPage.id
        }
        let showPage: @convention(block) (String) -> Void = { [weak self] id in
            guard let page = self?.Pages[id] else { return }
            if self?.rootNavigationController == nil {
                self?.rootNavigationController = UINavigationController(rootViewController: page)
                GetTopViewController()?.present(self!.rootNavigationController!, animated: true)
                return
            }
            self?.rootNavigationController?.pushViewController(page, animated: true)
        }
        
        let _pushPage: @convention(block) (String, String?) -> Void = { [weak self] pageId, title in
            if self == nil {
                return
            }
            let newPage = MiniV2ViewController()
            newPage.id = pageId
            newPage.title = title
            self!.Pages[newPage.id] = newPage
            self?.rootNavigationController?.pushViewController(newPage, animated: true)
        }
        
        context.setObject(callWebView, forKeyedSubscript: "callWebView" as NSCopying & NSObjectProtocol)
        context.setObject(newPage, forKeyedSubscript: "newPage" as NSCopying & NSObjectProtocol)
        context.setObject(_pushPage, forKeyedSubscript: "_pushPage" as NSCopying & NSObjectProtocol)
        
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let name = "react-custom-render"
        let url = URL(string: documentsURL.absoluteString + "\(name)") ?? documentsURL.appendingPolyfill(path: "\(name)")
        let entry = url.appendingPathComponent("index.js")
        runtime.context.evaluateScript(cat(url: entry), withSourceURL: entry)
    }
}

class MiniV2ViewController: UIViewController {
    var webview: WKWebView!
    var id = UUID().uuidString
    
    override func viewDidLoad() {
        webview = MWebViewPool.shared.getReusedWebView(forHolder: self)
        webview.uiDelegate = self
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(
                image: UIImage(systemName: "xmark"), style: .done, target: self, action: #selector(close)
            ),
            UIBarButtonItem(
                image: UIImage(systemName: "arrow.clockwise"), style: .done, target: self, action: #selector(refresh)
            )
        ]
        
        self.view = webview
        self.view.backgroundColor = .systemBackground
        
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        let name = "react-custom-render", page = "index.html"
        
        let url = URL(string: documentsURL.absoluteString + "\(name)") ?? documentsURL.appendingPolyfill(path: "\(name)")
        webview.loadFileURL(url.appendingPathComponent(page), allowingReadAccessTo: documentsURL)
    }
    
    deinit {
        if webview != nil {
            self.webview.tintColor = .systemBlue
            self.webview.scrollView.contentInsetAdjustmentBehavior = .always
            MWebViewPool.shared.recycleReusedWebView(self.webview as? MWebView)
            webview.uiDelegate = nil
            print("recycle")
        }
    }
    
    @objc
    func refresh() {
        webview.reload()
    }
    
    @objc
    func close() {
        self.dismiss(animated: true)
        MiniV2Egine.shared.clear()
    }
}

extension MiniV2ViewController: WKUIDelegate {
    
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (Bool) -> Void) {
        let alertController = UIAlertController(title: "", message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            completionHandler(false)
        }
        let okAction = UIAlertAction(title: "OK", style: .default) { _ in
            completionHandler(true)
        }
        alertController.addAction(cancelAction)
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                completionHandler()
            }
        )
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func webView(_ webView: WKWebView,
                 runJavaScriptTextInputPanelWithPrompt prompt: String,
                 defaultText: String?,
                 initiatedByFrame frame: WKFrameInfo,
                 completionHandler: @escaping (String?) -> Void) {
        if prompt == "id" {
//            print("get id")
            completionHandler(self.id)
            return
        }
        
        if MiniV2Egine.shared.useWKWebViewBackend {
            MiniV2Egine.shared.webviewBackend?.evaluateJavaScript(prompt)
        } else {
            MiniV2Egine.shared.runtime?.context.evaluateScript(prompt)
        }
//        print("call jscore")
        completionHandler(nil)
    }
}
