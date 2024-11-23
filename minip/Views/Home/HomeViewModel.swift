//
//  HomeViewController.swift
//  minip
//
//  Created by ByteDance on 2023/7/3.
//

import Foundation
import Defaults

class HomeViewModel: ObservableObject {
    @Published var apps: [AppInfo] = []
    
    @Published var selectedApp: AppInfo?
    @Published var deleteApp: AppInfo?
    @Published var showDeleteAlert = false
    
    init() {
        Task {
            loadAppInfos()
        }
    }

    func loadAppInfos() {
        let tmpApps = MiniAppManager.shared.getAppInfos()
        DispatchQueue.main.async {
            self.apps = tmpApps
        }
    }
    
    func getAppIconURL(appId: String) -> URL? {
        for ele in apps {
            if ele.id != appId {
                continue
            }
            guard let icon = ele.icon else {
                return nil
            }
            if icon.starts(with: "http://") || icon.starts(with: "https://") {
                return URL(string: icon)
            }
            return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.appendingPolyfill(path: ele.name).appendingPolyfill(path: icon)
        }
        return nil
    }
}

struct AppInfo: Hashable, Identifiable, Codable, Defaults.Serializable {
    var name: String
    var appId: String
    var author: String?
    var website: String?
    var icon: String?
    var version: String? // v{x.x.x}, like v0.0.1
    var description: String?
    var displayMode: String? // multiple-webview, signle-webview(default)
    var homepage: String
    var title: String? // homepage title
    var pages: [PageConfig]? // unuse
    var tabs: [TabConfig]?
    var navigationBarStatus: String? // display, hidden(default)
    var colorScheme: String? // dark, light (default auto)
    var disableSwipeBackGesture: Bool?
    
    // can be override in PageConfig
    var backgroundColor: String? // hex string
    var navigationBarColor: String?
    var tintColor: String? // hex string
    
    // web server
    var webServerEnabled: Bool?
    
    var id: String {
        return appId
    }
    struct PageConfig: Hashable, Codable {
        var path: String
        var title: String?
        var scrollable: Bool?
        
        // override
        var backgroundColor: String?
        var navigationBarColor: String?
    }

    struct TabConfig: Hashable, Codable {
        var path: String
        var title: String
        var systemImage: String
    }
}
