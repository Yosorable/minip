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

/// Runtime representation of an installed project or a development session.
///
/// `AppInfo.name` belongs to the project manifest and must not be used to
/// locate the project after installation. `rootURL` is discovered while
/// scanning Documents and remains fixed for the lifetime of a running
/// project session. Development sessions use a temporary root and load
/// their pages from `developmentServerURL` instead.
struct InstalledProject: Hashable {
    let appInfo: AppInfo
    let rootURL: URL
    let developmentServerURL: URL?

    init(appInfo: AppInfo, rootURL: URL, developmentServerURL: URL? = nil) {
        self.appInfo = appInfo
        self.rootURL = rootURL.standardizedFileURL
        self.developmentServerURL = developmentServerURL
    }

    var appId: String {
        appInfo.appId
    }

    var title: String {
        if let displayName = appInfo.displayName, !displayName.isEmpty {
            return displayName
        }
        return developmentServerURL == nil ? rootURL.lastPathComponent : appInfo.name
    }

    /// Native routes are relative to the project root, including routes starting with `/`.
    func developmentURL(for path: String) -> URL? {
        guard let developmentServerURL else { return nil }
        if let url = URL(string: path), ["http", "https"].contains(url.scheme?.lowercased() ?? "") {
            return url
        }
        let relativePath = String(path.drop(while: { $0 == "/" }))
        guard let url = URL(string: relativePath, relativeTo: developmentServerURL)?.absoluteURL,
              ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil else { return nil }
        return url
    }

    var launchURL: String {
        if let developmentServerURL {
            var allowed = CharacterSet.alphanumerics
            allowed.insert(charactersIn: "-._~")
            let address = developmentServerURL.absoluteString.addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            return "minip://dev/\(address)"
        }
        return "minip://open/\(appId)"
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
