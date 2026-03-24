//
//  PromptAndAlert.swift
//  minip
//
//  Created by LZY on 2025/3/7.
//

import UIKit
import WebKit

extension MiniPageViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping () -> Void) {
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            completionHandler()
        }))
        alertController.view.tintColor = webView.tintColor
        present(alertController, animated: true)
    }
}

extension MiniPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    }
}
