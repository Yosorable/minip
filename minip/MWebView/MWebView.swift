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

        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true
        config.allowsPictureInPictureMediaPlayback = true
        config.limitsNavigationsToAppBoundDomains = false
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.upgradeKnownHostsToHTTPS = false
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let overrideConsole = """
                function log(emoji, type, args) {
                  window.webkit.messageHandlers.logging.postMessage(
                    `${emoji} JS ${type}: ${Object.values(args)
                      .map(v => typeof(v) === "undefined" ? "undefined" : typeof(v) === "object" ? JSON.stringify(v) : v.toString())
                      .map(v => v.substring(0, 5000)) // Limit msg to 5000 chars
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

        let interceptImgSrc = """
                (function() {
                    function rewriteSrc(src) {
                        if (typeof src !== 'string') return src;
                        if (src.startsWith('http://')) return 'minipimghttp' + src.substring(4);
                        if (src.startsWith('https://')) return 'minipimghttps' + src.substring(5);
                        return src;
                    }

                    function restoreSrc(src) {
                        if (typeof src !== 'string') return src;
                        if (src.startsWith('minipimghttp://')) return 'http' + src.substring(12);
                        if (src.startsWith('minipimghttps://')) return 'https' + src.substring(13);
                        return src;
                    }

                    const srcDesc = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
                    Object.defineProperty(HTMLImageElement.prototype, 'src', {
                        get: function() { return restoreSrc(srcDesc.get.call(this)); },
                        set: function(v) { srcDesc.set.call(this, rewriteSrc(v)); },
                        configurable: true, enumerable: true
                    });

                    const origGetAttr = Element.prototype.getAttribute;
                    const origSetAttr = Element.prototype.setAttribute;
                    Element.prototype.getAttribute = function(name) {
                        if (this instanceof HTMLImageElement && name.toLowerCase() === 'src') {
                            return restoreSrc(origGetAttr.call(this, name));
                        }
                        return origGetAttr.call(this, name);
                    };
                    Element.prototype.setAttribute = function(name, value) {
                        if (this instanceof HTMLImageElement && name.toLowerCase() === 'src') {
                            origSetAttr.call(this, name, rewriteSrc(value));
                        } else {
                            origSetAttr.call(this, name, value);
                        }
                    };

                    new MutationObserver(function(mutations) {
                        mutations.forEach(function(m) {
                            m.addedNodes.forEach(function(node) {
                                if (node.nodeType !== 1) return;
                                var imgs = node.tagName === 'IMG' ? [node] : [];
                                if (node.querySelectorAll) {
                                    imgs = imgs.concat(Array.from(node.querySelectorAll('img')));
                                }
                                imgs.forEach(function(img) {
                                    var s = img.getAttribute('src');
                                    if (s && (s.startsWith('http://') || s.startsWith('https://'))) {
                                        img.setAttribute('src', rewriteSrc(s));
                                    }
                                });
                            });
                        });
                    }).observe(document, { childList: true, subtree: true });
                })();
            """

        let userContentController = WKUserContentController()
        userContentController.add(LoggingMessageHandler(), name: "logging")
        userContentController.addUserScript(WKUserScript(source: overrideConsole, injectionTime: .atDocumentStart, forMainFrameOnly: true))
        userContentController.addUserScript(WKUserScript(source: interceptImgSrc, injectionTime: .atDocumentStart, forMainFrameOnly: false))
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
        let dataTypes = [
            WKWebsiteDataTypeMemoryCache, WKWebsiteDataTypeCookies, WKWebsiteDataTypeSessionStorage, WKWebsiteDataTypeOfflineWebApplicationCache, WKWebsiteDataTypeOfflineWebApplicationCache,
            WKWebsiteDataTypeCookies, WKWebsiteDataTypeLocalStorage, WKWebsiteDataTypeIndexedDBDatabases, WKWebsiteDataTypeWebSQLDatabases,
        ]
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

        load(URLRequest(url: URL(string: "about:blank")!))

        if #available(iOS 16.4, *) {
            isInspectable = false
        }
    }
}
