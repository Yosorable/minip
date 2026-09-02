//
//  AppInfo.swift
//  minip
//
//  Created by LZY on 2025/2/1.
//

import UIKit

struct AppInfo: Hashable, Codable {
    var name: String // manifest/package name; only suggests the initial directory name
    var displayName: String? // optional user-facing project name
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

    var files: [File]? // file list

    // MARK: For iOS

    var iOS_disableSwipeBackGesture: Bool?
    var iOS_disableTextInteraction: Bool?
    var iOS_scrollbar: ScrollbarConfig?
}

/// Runtime representation of an installed project.
///
/// `AppInfo.name` belongs to the project manifest and must not be used to
/// locate the project after installation. `rootURL` is discovered while
/// scanning Documents and remains fixed for the lifetime of a running
/// project session.
struct InstalledProject: Hashable {
    let appInfo: AppInfo
    let rootURL: URL

    init(appInfo: AppInfo, rootURL: URL) {
        self.appInfo = appInfo
        self.rootURL = rootURL.standardizedFileURL
    }

    var appId: String {
        appInfo.appId
    }

    var title: String {
        if let displayName = appInfo.displayName, !displayName.isEmpty {
            return displayName
        }
        return rootURL.lastPathComponent
    }
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
        var disableBounces: Bool? // enable pull to refresh will disable this config
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
