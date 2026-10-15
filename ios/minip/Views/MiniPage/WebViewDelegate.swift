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
        alertController.addAction(UIAlertAction(title: String(localized: "OK"), style: .default, handler: { _ in
            completionHandler()
        }))
        alertController.view.tintColor = webView.tintColor
        present(alertController, animated: true)
    }
}

extension MiniPageViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        developmentErrorView?.removeFromSuperview()
        developmentErrorView = nil
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        showDevelopmentLoadError(error)
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        showDevelopmentLoadError(error)
    }

    func showDevelopmentLoadError(_ error: Error) {
        guard project.developmentServerURL != nil, (error as NSError).code != NSURLErrorCancelled else { return }
        if let failedURL = (error as NSError).userInfo[NSURLErrorFailingURLErrorKey] as? URL,
           ["http", "https"].contains(failedURL.scheme?.lowercased() ?? "") {
            page = failedURL.absoluteString
            pageURL = failedURL
        }
        developmentErrorView?.removeFromSuperview()
        let background = UIView()
        background.backgroundColor = .systemBackground
        background.translatesAutoresizingMaskIntoConstraints = false
        let message = UILabel()
        message.text = String(localized: "Could not connect to the development server") + "\n\n" + String(localized: "Keep the server running, connect your phone and computer to the same network, and allow Minip to access the local network in Settings.") + "\n\n" + error.localizedDescription
        message.font = .systemFont(ofSize: 15)
        message.textColor = .secondaryLabel
        message.textAlignment = .center
        message.numberOfLines = 0
        let retry = UIButton(type: .system)
        retry.setTitle(String(localized: "Retry"), for: .normal)
        retry.addAction(UIAction { [weak self] _ in self?.loadPage() }, for: .touchUpInside)
        let close = UIButton(type: .system)
        close.setTitle(String(localized: "Close"), for: .normal)
        close.addAction(UIAction { [weak self] _ in self?.close() }, for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [message, retry, close])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        background.addSubview(stack)
        view.addSubview(background)
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            background.topAnchor.constraint(equalTo: view.topAnchor),
            background.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: background.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: background.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: background.safeAreaLayoutGuide.centerYAnchor),
        ])
        developmentErrorView = background
    }
}
