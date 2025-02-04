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

    static func defaultConfiguration() -> WKWebViewConfiguration {
        let config = WKWebViewConfiguration()

        config.preferences = WKPreferences()
//        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.userContentController = WKUserContentController()

        config.mediaTypesRequiringUserActionForPlayback = []
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.setValue(true, forKey: "allowUniversalAccessFromFileURLs")
        config.allowsInlineMediaPlayback = true

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

    /// 即将被复用
    func webviewWillLeavePool() {

    }

    /// 被回收
    func webviewWillEnterPool() {
        id = nil
        holderObject = nil
        scrollView.delegate = nil
        stopLoading()
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        navigationDelegate = nil
        uiDelegate = nil
        // 删除历史记录
        let selStr = "_re" + "mov" + "eA" + "llIt" + "ems"
        let sel = Selector(selStr)
        if self.backForwardList.responds(to: sel) {
            self.backForwardList.perform(sel)
        }
        #warning("使用自定义的移除占位图")
        loadHTMLString("", baseURL: nil)
        
        
        if #available(iOS 16.4, *) {
            isInspectable = false
        }
    }
}
