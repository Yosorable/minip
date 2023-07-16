//
//  MiniPageView.swift
//  minip
//
//  Created by ByteDance on 2023/7/1.
//

import SwiftUI

// 使用原生导航的小程序的每个页面，每个页面独享一个webview
//
//  ViewController.swift
//  UIKitWebViewTest
//
//  Created by ByteDance on 2023/7/2.
//

import SwiftUI
import UIKit
import WebKit

class _MiniPageViewController: UIViewController {
    
    //    let webView = WKWebView()
    var _webView: WKWebView?
    var _filePath: String?
    
    init(webView: WKWebView, filePath: String) {
        super.init(nibName: nil, bundle: nil)
        self._webView = webView
        self._filePath = filePath
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let webView = _webView!
        let filePath = _filePath!
        
        webView.frame = view.bounds // 或者你可以使用约束设置webView的frame
        webView.translatesAutoresizingMaskIntoConstraints = false // 如果使用约束，确保将其设置为false
        view.addSubview(webView)
        print("\(view.bounds)")
        
        let url = Bundle.main.url(forResource: filePath, withExtension: nil, subdirectory: "static")!
        webView.loadFileURL(url, allowingReadAccessTo: url)
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    
}

struct _MiniPageView: UIViewControllerRepresentable {
    var webview: WKWebView
    var filePath: String
    func makeUIViewController(context: Context) -> _MiniPageViewController {
        return _MiniPageViewController(webView: webview, filePath: filePath)
    }
    
    func updateUIViewController(_ uiViewController: _MiniPageViewController, context: Context) {
    }
}
