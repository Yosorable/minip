//
//  MWebView.swift
//  minip
//
//  Created by LZY on 2023/11/1.
//

import UIKit
import WebKit

protocol MWebViewProtocol: AnyObject {
    func clearAllWebCache()
}

public class MWebView: WKWebView {
    weak var holderObject: AnyObject?
    var id: Int?

    // hide keyboard tool bar
    override public var inputAccessoryView: UIView? {
        return nil
    }

    static func defaultConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        config.preferences = WKPreferences()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.userContentController = WKUserContentController()

        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true

        let overrideConsole = """
            function log(emoji, type, args) {
              window.webkit.messageHandlers.logging.postMessage(
                `${emoji} JS ${type}: ${Object.values(args)
                  .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
                  .map(v => v.substring(0, 3000)) // Limit msg to 3000 chars
                  .join(", ")}`
              )
            }

            let originalLog = console.log
            let originalWarn = console.warn
            let originalError = console.error
            let originalDebug = console.debug

            console.log = function() { log("📗", "log", arguments); originalLog.apply(null, arguments) }
            console.warn = function() { log("📙", "warning", arguments); originalWarn.apply(null, arguments) }
            console.error = function() { log("📕", "error", arguments); originalError.apply(null, arguments) }
            console.debug = function() { log("📘", "debug", arguments); originalDebug.apply(null, arguments) }

            window.addEventListener("error", function(e) {
               log("💥", "Uncaught", [`${e.message} at ${e.filename}:${e.lineno}:${e.colno}`])
            })
        """

        class LoggingMessageHandler: NSObject, WKScriptMessageHandler {
            func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
                if let msg = message.body as? String {
                    logger.debug("\(msg)")
                    MiniAppManager.shared.appendWebViewLog(msg)
                    NotificationCenter.default.post(name: .logAppended, object: nil, userInfo: ["message": msg])
                }
            }
        }

        let userContentController = WKUserContentController()
        userContentController.add(LoggingMessageHandler(), name: "logging")
        userContentController.addUserScript(WKUserScript(source: overrideConsole, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        config.userContentController = userContentController

        return config
    }

    deinit {
        // remove UserScript
        configuration.userContentController.removeAllUserScripts()
        // stop loading
        stopLoading()
        uiDelegate = nil
        navigationDelegate = nil
        // holder set nil
        holderObject = nil
    }
}

extension MWebView: MWebViewProtocol {
    func clearAllWebCache() {
        let dataTypes = [WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases]
        let websiteDataTypes = Set(dataTypes)
        let dateFrom = Date(timeIntervalSince1970: 0)

        WKWebsiteDataStore.default().removeData(ofTypes: websiteDataTypes, modifiedSince: dateFrom) {}
    }
}

extension MWebView: MWebViewPoolProtocol {
    /// will be reused
    func webviewWillLeavePool() {}

    /// be recycled
    func webviewWillEnterPool() {
        id = nil
        holderObject = nil
        scrollView.delegate = nil
        stopLoading()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        navigationDelegate = nil
        uiDelegate = nil
        // remove history
        let selStr = "_re" + "mov" + "eA" + "llIt" + "ems"
        let sel = Selector(selStr)
        if backForwardList.responds(to: sel) {
            backForwardList.perform(sel)
        }

        loadHTMLString("", baseURL: nil)

        if #available(iOS 16.4, *) {
            isInspectable = false
        }
    }
}
