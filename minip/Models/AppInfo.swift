//
//  AppInfo.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import Defaults

struct AppInfo: Hashable, Identifiable, Codable, Defaults.Serializable {
    var name: String
    var displayName: String?
    var appId: String
    var author: String?
    var website: String?
    var icon: String?
    var version: String? // x.x.x (0.0.1)
    var description: String?
    var displayMode: String? // multiple-webview, signle-webview(default)
    var homepage: String
    var title: String? // homepage title
    var tabs: [TabConfig]?
    var navigationBarStatus: String? // display, hidden(default)
    var colorScheme: String? // dark, light (default auto)
    var disableSwipeBackGesture: Bool?
    var alwaysInSafeArea: Bool? // webview safearea layout

    var backgroundColor: String? // hex string
    var tintColor: String? // hex string

    // web server
    var webServerEnabled: Bool?
    // orientation
    var orientation: String? // landscape, portrait, all by default
    
    // MARK: For iOS (14.5)
    var iOS_disableTextInteraction: Bool?

    // file list
    var files: [File]?

    var id: String {
        return appId
    }

    struct TabConfig: Hashable, Codable {
        var path: String
        var title: String
        var systemImage: String
    }

    struct File: Hashable, Codable {
        var name: String
        var path: String
    }
}
