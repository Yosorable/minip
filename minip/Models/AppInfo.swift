//
//  AppInfo.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import Defaults
import UIKit

struct AppInfo: Hashable, Codable, Defaults.Serializable {
    var name: String
    var displayName: String?
    var appId: String
    var author: String?
    var website: String?
    var icon: String?
    var version: String? // x.x.x (0.0.1)
    var description: String?
    var homepage: String
    var title: String? // homepage title
    var tabs: [TabConfig]?
    var navigationBarStatus: String? // display, hidden(default)
    var colorScheme: String? // dark, light (default auto)
    var alwaysInSafeArea: Bool? // webview safearea layout
    var backgroundColor: String? // css name or hex
    var tintColor: String? // css name or hex
    var webServerEnabled: Bool? // web server
    var orientation: String? // landscape, portrait, all by default

    @available(*, deprecated, message: "This value only stored in the app.json file, not in UserDefaults")
    var files: [File]? // file list

    // MARK: For iOS

    var iOS_disableSwipeBackGesture: Bool?
    var iOS_disableTextInteraction: Bool? // iOS 14.5+
    var iOS_scrollbar: ScrollbarConfig?
}

extension AppInfo {
    struct TabConfig: Hashable, Codable {
        var path: String
        var title: String
        var systemImage: String
    }

    struct File: Hashable, Codable {
        var name: String
        var path: String
    }

    struct ScrollbarConfig: Hashable, Codable {
        var hide: Bool?
        var verticalInsets: EdgeInsets?
        var horizontalInsets: EdgeInsets?
    }

    struct EdgeInsets: Hashable, Codable {
        var top: CGFloat?
        var left: CGFloat?
        var bottom: CGFloat?
        var right: CGFloat?

        func toUIEdgeInsets() -> UIEdgeInsets {
            UIEdgeInsets(top: top ?? .zero, left: left ?? .zero, bottom: bottom ?? .zero, right: right ?? .zero)
        }
    }
}
