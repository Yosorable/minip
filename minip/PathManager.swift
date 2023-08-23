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

struct RouteParameter: Hashable {
    var path: String
    var title: String?
}

class PathManager: ObservableObject{
    @Published var path: [RouteParameter] = []
    var appTmpStore: [String:String] = [String:String]()
    var openedApp: AppInfo? = nil
    
    init() {
    }
}

var pathManager = PathManager()
