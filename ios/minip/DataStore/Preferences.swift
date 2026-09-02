//
//  Preferences.swift
//  minip
//
//  Created by ByteDance on 2023/7/14.
//

import Foundation

/// Typed access to values stored in `UserDefaults`.
///
/// The key names intentionally match the previously used Defaults package so
/// existing preference values remain available.
enum Preferences {
    enum Key {
        static let lastDownloadedURL = "lastDownloadedURL"
        static let appSortList = "appSortList"
        static let wkwebviewInspectable = "wkwebviewInspectable"
        static let useCapsuleButton = "useCapsuleButton"
        static let firstStart = "firstStart"
        static let colorScheme = "colorScheme"
        static let useSandboxRoot = "useSandboxRoot"
        static let enableWebView120FPS = "enableWebView120FPS"
        static let lastTabIndex = "lastTabIndex"
        static let filebrowserLastFolder = "filebrowserLastFolder"
    }

    private static var store: UserDefaults { .standard }

    static var lastDownloadedURL: String {
        get { store.string(forKey: Key.lastDownloadedURL) ?? "" }
        set { store.set(newValue, forKey: Key.lastDownloadedURL) }
    }

    static var appSortList: [String] {
        get { store.stringArray(forKey: Key.appSortList) ?? [] }
        set { store.set(newValue, forKey: Key.appSortList) }
    }

    static var wkwebviewInspectable: Bool {
        get { store.bool(forKey: Key.wkwebviewInspectable) }
        set { store.set(newValue, forKey: Key.wkwebviewInspectable) }
    }

    static var useCapsuleButton: Bool {
        get { store.bool(forKey: Key.useCapsuleButton) }
        set { store.set(newValue, forKey: Key.useCapsuleButton) }
    }

    static var firstStart: Bool {
        get { store.object(forKey: Key.firstStart) as? Bool ?? true }
        set { store.set(newValue, forKey: Key.firstStart) }
    }

    static var colorScheme: Int {
        get { store.integer(forKey: Key.colorScheme) }
        set { store.set(newValue, forKey: Key.colorScheme) }
    }

    static var useSandboxRoot: Bool {
        get { store.bool(forKey: Key.useSandboxRoot) }
        set { store.set(newValue, forKey: Key.useSandboxRoot) }
    }

    static var enableWebView120FPS: Bool {
        get { store.object(forKey: Key.enableWebView120FPS) as? Bool ?? true }
        set { store.set(newValue, forKey: Key.enableWebView120FPS) }
    }

    static var lastTabIndex: Int {
        get { store.integer(forKey: Key.lastTabIndex) }
        set { store.set(newValue, forKey: Key.lastTabIndex) }
    }

    static var filebrowserLastFolder: String {
        get { store.string(forKey: Key.filebrowserLastFolder) ?? "Documents" }
        set { store.set(newValue, forKey: Key.filebrowserLastFolder) }
    }
}
