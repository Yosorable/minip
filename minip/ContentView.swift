//
//  ContentView.swift
//  minip
//
//  Created by LZY on 2022/7/24.
//

import SwiftUI
import WKWebViewJavascriptBridge
import JavaScriptCore
import WebKit

struct ContentView: View {
    @State var showAlert = false
    @State var alertTitle = ""
    @State var alertMsg = ""
    @State var startFile = "alert_test.html"
//    @State var startFile = "build/index.html"
//    @State var startFile = "worker_test/index.html"
    
    
    @StateObject var _pathManager = pathManager
    
    var bridge: WKWebViewJavascriptBridge
    var webview: FullScreenWKWebView
    
    
    
    init() {
        webview = FullScreenWKWebView()
        webview.allowsLinkPreview = false
//        webview.allowsBackForwardNavigationGestures = true
//        webview.scrollView.isScrollEnabled = false
//        webview.isOpaque = false
//        webview.backgroundColor = .clear
//
////        let top: CGFloat = UIApplication.shared.keyWindow?.safeAreaInsets.top ?? UIApplication.shared.statusBarFrame.size.height
//        let top = UIApplication.shared.firstKeyWindow?.safeAreaInsets.top ?? 300
//        print(top)
////        let top = getSafeAreaTop()
//        webview.scrollView.contentInset = UIEdgeInsets(top: 55, left: 0, bottom: 0, right: 0)

        bridge = WKWebViewJavascriptBridge(webView: webview)
        
//        let context = JSContext()
        
    }
    
    func register() {
        bridge.register(handlerName: "showMsg") { (paramters, callback) in
            self.alertTitle = paramters!["title"] as! String
            self.alertMsg = paramters!["msg"] as! String
            self.showAlert.toggle()
        }
        bridge.register(handlerName: "navigateTo") { (paramters, callback) in
            _pathManager.path.append("/sub_view.html")
        }
    }
    
    var body: some View {
        ZStack {
            GeometryReader { geoProxy in
                NavigationStack(path: $_pathManager.path) {
                    ZStack {
                        WebView(startFile: startFile, wkwebview: webview)
                            .edgesIgnoringSafeArea(.all)
                            .alert(isPresented: $showAlert) {
                                Alert(title: Text(alertTitle),
                                      message: Text(alertMsg),
                                      dismissButton: .default(Text("OK")))
                            }
                            .onAppear{
                                print("appear")
                                register()
                            }
                        
                    }
                    .navigationDestination(for: String.self) { target in
                        LazyView {
                            SubView(id: UUID())
                                .environmentObject(pathManager)
                                .onDisappear {
                                    pathManager.popIfNeed()
                                }
                            
                        }
                    }
                    .navigationTitle(Text("Home"))
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItemGroup(placement: .navigationBarTrailing) {
                            Button {} label: {
                                Image(systemName: "ellipsis")
                            }
                            Button {} label: {
                                Image(systemName: "xmark")
                            }
                        }
                    }
                }
                
                VStack {
                    Spacer()
                    Button {
                        print("\(pathManager.path.count), \(pathManager.path.description)")
                        print("webviews: \(pathManager.webviews.count)")
                        
                    } label: {
                        Text("show path")
                    }
                }
            }
        }.preferredColorScheme(.light)
    }
}

struct LazyView<Content: View>: View {
    var content: () -> Content
    var body: some View {
        self.content()
    }
}

class PathManager: ObservableObject{
    @Published var path:[String] = []
    var webviews: [WKWebView] = []
    var bridges: [WKWebViewJavascriptBridge] = []
    var newWebview: WKWebView
    var newBridge: WKWebViewJavascriptBridge
    
    // app tmp store in runtime, it will be cleared when app is closed
    var appTmpStore: [String:String] = [String:String]()
    var openedApp: AppInfo? = nil
    
    init() {
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        
        newWebview = WKWebView(frame: .zero, configuration: cfg)
        newWebview.loadHTMLString("", baseURL: nil)
        newBridge = WKWebViewJavascriptBridge(webView: newWebview)
    }
    
    func push() {
//        webviews.append(newWebview)
//        bridges.append(newBridge)
        let cfg = WKWebViewConfiguration()
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        newWebview = WKWebView(frame: .zero, configuration: cfg)
        newWebview.loadHTMLString("", baseURL: nil)
        newBridge = WKWebViewJavascriptBridge(webView: newWebview)
    }
    
    
    func popIfNeed() {
//        while webviews.count - path.count > 0 {
//            let lastWebview = webviews.popLast()
//            lastWebview?.stopLoading()
//            bridges.removeLast()
//        }
//        print("cnt: \(path.count) \(webviews.count)")
    }
}

var pathManager = PathManager()
