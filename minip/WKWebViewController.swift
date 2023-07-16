//
//  WKWebViewController.swift
//  minip
//
//  Created by LZY on 2022/7/24.
//

import SwiftUI
import WebKit

struct WebView: UIViewRepresentable {
    var startFile: String
    var wkwebview: WKWebView
    func makeUIView(context: Context) -> WKWebView {
//        wkwebview.isOpaque = false
//        wkwebview.backgroundColor = .black
        wkwebview.scrollView.contentInsetAdjustmentBehavior = .always
        return wkwebview
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        let url = Bundle.main.url(forResource: startFile, withExtension: nil, subdirectory: "static")!
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        webView.loadFileURL(url, allowingReadAccessTo: documentsURL)
    }
}

struct WebViewWithURL: UIViewRepresentable {
    var url: URL
    var wkwebview: WKWebView
    func makeUIView(context: Context) -> WKWebView {
//        wkwebview.isOpaque = false
//        wkwebview.backgroundColor = .black
        wkwebview.scrollView.contentInsetAdjustmentBehavior = .always
        
        return wkwebview
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        wkwebview.loadFileURL(url, allowingReadAccessTo: documentsURL)
    }
}

class FullScreenWKWebView: WKWebView {
//    var _safeAreaInsets: UIEdgeInsets?
//    override var safeAreaInsets: UIEdgeInsets {
//        return _safeAreaInsets ?? .zero
//    }
}

struct WebView2: UIViewRepresentable {
    var startFile: String
    var wkwebview: WKWebView
    func makeUIView(context: Context) -> UIView {
//        wkwebview.isOpaque = false
//        wkwebview.backgroundColor = .black
        let newView = UIView(frame: UIScreen.main.bounds)
        wkwebview.frame = newView.bounds // 或者你可以使用约束设置webView的frame
        
        print("\(newView.bounds)")
        wkwebview.translatesAutoresizingMaskIntoConstraints = false // 如果使用约束，确保将其设置为false
        newView.addSubview(wkwebview)
        
        return newView
    }

    func updateUIView(_ webView: UIView, context: Context) {
        let url = Bundle.main.url(forResource: startFile, withExtension: nil, subdirectory: "static")!
        wkwebview.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        wkwebview.load(request)
    }
}
